import re
import unicodedata
import pandas as pd

def debug_unicode(a, b):
    for i, (ca, cb) in enumerate(zip(a, b)):
        if ca != cb:
            print(f"Khác tại vị trí {i}: '{ca}' ({ord(ca)}) vs '{cb}' ({ord(cb)})")


# Các ký tự/vệt vô hình hay gặp
INVISIBLES = [
    "\ufeff",   # BOM
    "\u200b",   # zero-width space
    "\u200c",   # ZWNJ
    "\u200d",   # ZWJ
    "\u2060",   # word joiner
]
# thay thế chúng bằng rỗng
INV_RE = re.compile("|".join(map(re.escape, INVISIBLES)))

# Homoglyph & ký tự “sai hệ chữ” thường gặp
HOMOGLYPHS = {
    "Ð": "Đ", "ð": "đ",          # ETH (Icelandic) → D gạch (VN)
    "İ": "I",  "ı": "i",         # Turkish dotted/ dotless I → Latin
    "’": "'",  "‚": ",", "‛": "'", "“": '"', "”": '"', "„": '"',
    "‐": "-", "-": "-", "‒": "-", "–": "-", "—": "-", "―": "-",  # nhiều loại gạch nối
    "\xa0": " ",                 # NBSP → space thường
}
PAIR = {
    "oá": "óa",
    "oà": "òa",
    "oả": "ỏa",
    "oã": "õa",
    "oạ": "ọa",
}

# Dấu tiếng Việt dưới dạng “tổ hợp” (nếu có)
COMBINING_TONE = {"\u0300", "\u0301", "\u0303", "\u0309", "\u0323"}  # huyền, sắc, ngã, hỏi, nặng
COMBINING_SHAPES = {"\u0302", "\u0306", "\u031B"}                    # ^, ˘, ̛  (ô/â/ă/ơ/ư)

def normalize_vi_text(s: str) -> str:
    if s == 'Huế': s = 'Thừa Thiên Huế'
    if s == 'Bắc Trung Bộ và Duyên hải miền Trung': s = 'Bắc Trung Bộ và duyên hải miền Trung'
    if s == 'TP.Hồ Chí Minh': s = 'TP. Hồ Chí Minh'
    if not isinstance(s, str):
        return s

    # 1) Bỏ ký tự ẩn + chuẩn hoá khoảng trắng
    s = INV_RE.sub("", s)
    s = s.replace("\xa0", " ")          # NBSP
    s = s.strip()
    # gom nhiều khoảng trắng về 1
    s = re.sub(r"\s+", " ", s)

    # 2) Thay homoglyphs sang ký tự Latin/Việt chuẩn và chuẩn hóa vị trí của dấu
    if HOMOGLYPHS:
        s = "".join(HOMOGLYPHS.get(ch, ch) for ch in s)
    for k,v in PAIR.items():
        s = re.sub(rf'\b{k}',v,s)
        s = re.sub(rf'{k}\b',v,s)
    # 3) “NFD → xử lý → NFC” để gộp dấu đúng chuẩn
    #    - NFD tách dấu ra; NFC gộp lại theo thứ tự chuẩn Unicode
    s = unicodedata.normalize("NFD", s)

    # Đề phòng dữ liệu có dấu/shape dính nhầm vào ký tự khác,
    # ta chỉ giữ các dấu kết hợp hợp lệ, bỏ dấu rác hiếm gặp.
    cleaned = []
    for ch in s:
        # Bỏ các combining không phải dấu/shape tiếng Việt (rất hiếm)
        if unicodedata.combining(ch) and (ch not in COMBINING_TONE | COMBINING_SHAPES):
            continue
        cleaned.append(ch)
    s = "".join(cleaned)

    # 4) Gộp lại thành dạng chuẩn (precomposed) – cực quan trọng khi merge
    s = unicodedata.normalize("NFC", s)
    return s

def normalize_vi_df(df: pd.DataFrame) -> pd.DataFrame:
    # Chuẩn hoá tiêu đề cột
    df.columns = [normalize_vi_text(c) if isinstance(c, str) else c for c in df.columns]
    # Chuẩn hoá toàn bộ cột kiểu object (string)
    for col in df.select_dtypes(include="object").columns:
        df[col] = df[col].map(normalize_vi_text)
    return df
