import unidecode
import opencc
import os

INITIALS = [
    'q', 'w', 'e', 'r', 't', 'y', 'sh', 'ch', 'o', 'p',
    'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',
    'z', 'x', 'c', 'zh', 'b', 'n', 'm'
]

# maps initials to key in keyboard & vice versa, e.g.
#   q <-> q
#   a <-> a (a is considered an initial)
#   ch <-> i
INITIALS2KEY = {
    'sh': 'u',
    'ch': 'i',
    'zh': 'v'
}
KEY2INITIALS = {
    'u': 'sh',
    'i': 'ch',
    'v': 'zh'
}

PINYIN_FILES = [
    "./pinyin-data/kTGHZ2013.txt",
    "./pinyin-data/kHanyuPinlu.txt",
    "./pinyin-data/cc_cedict.txt",
    "./pinyin-data/kMandarin_8105.txt",
    "./pinyin-data/kXHC1983.txt",
]

TARGET_FILE  = 'pinyinlib.el'
TARGET_START = ';;; DICT STARTS HERE'
TARGET_END   = ';;; DICT ENDS HERE'

initials2char = {}              # 声母转汉字 code point


# returns (unicode, character, a list of initials)
def parse_line(line):
    # line:      U+4E2D: zhōng,zhòng  # 中
    # raw_line:  U+4E2D: zhōng,zhòng
    raw_line = line.split('#')[0].strip()
    # character: 中
    character = line.split('#')[1].strip().split()[0].strip()
    # ucode:     U+4E2D -> 0x4E2D
    ucode = line.split(':')[0].strip()
    assert ucode.startswith("U+")
    ucode = int(ucode[2:], base=16)
    # accents:   zhōng,zhòng
    accents = line.split(':')[1].strip()
    # initials:  ['zh']
    initials = []
    for accent_py in accents.split(','):
        # remove accent: zhōng -> zhong
        py = unidecode.unidecode(accent_py.strip()).lower()
        if py[:2] in INITIALS:
            initials.append(py[:2])
        elif py[:1] in INITIALS:
            initials.append(py[:1])

    return ucode, character, initials


# Use Unicode CJK Unified Ideographs (U+4E00--U+9FFF) to determine
# whether character is common
# https://en.wikipedia.org/wiki/CJK_Unified_Ideographs_(Unicode_block)
def is_common_char(ucode, character):
    return 0x4E00 <= ucode <= 0x9FFF


def add_dict(pinyin_file):
    with open(pinyin_file) as f:
        for line in f:
            line = line.strip()
            if line.startswith('#') or not line:
                continue

            ucode, character, initials = parse_line(line)

            # skip non-common characters
            if not is_common_char(ucode, character):
                continue

            # doesn't have suitable initials
            if len(initials) == 0:
                continue

            for i in initials:
                initials2char[i].add(character)


def demo(s):
    for char in s:
        l = []
        for i, chars in initials2char.items():
            if char in chars:
                l.append(i)
        print(char, l, [INITIALS2KEY[i] for i in l])


def save_dict_as_elisp(var, converter=None):
    print(f'Generate for var "{var}" '
          f'{"with" if converter is not None else "without"}'
          f' converter')
    lines = [f"(defconst {var} '(\n"]
    for i in range(26):
        key = chr(i + ord('a'))
        initials = KEY2INITIALS[key]
        chars = ''.join(initials2char[initials])
        if converter is not None:
            chars = converter.convert(chars)
        lines.append('  "' + chars + '"\n')
        print(f'  {key} -> {initials}: {len(chars)} chars')
    lines.append("))\n")
    return lines


def save_to_file(src_lines):
    with open(TARGET_FILE) as f:
        result = f.readlines()
    l, r = -1, -1
    for i, line in enumerate(result):
        line = line.strip()
        if line == TARGET_START:
            assert l == -1
            l = i
        elif line == TARGET_END:
            assert r == -1
            r = i
    assert l != -1 and r != -1
    result[l+1:r] = src_lines
    with open(TARGET_FILE, 'w') as f:
        f.writelines(result)


def main():
    for i in INITIALS:
        initials2char[i] = set()
        if len(i) == 1:
            KEY2INITIALS[i] = i
            INITIALS2KEY[i] = i

    for f in PINYIN_FILES:
        add_dict(f)

    demo('我看你是个大笨蛋')
    demo('重庆')

    lines = []
    lines += save_dict_as_elisp("pinyinlib--simplified-char-table")
    lines += save_dict_as_elisp("pinyinlib--traditional-char-table",
                                opencc.OpenCC('s2t.json'))

    save_to_file(lines)

if __name__ == "__main__":
    main()
