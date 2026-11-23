"""Pull author / avatar / stats / caption for the user's chosen Instagram posts.

The /embed/captioned/ endpoint is server-rendered only for crawler user agents,
which is what makes this possible without a logged-in session.
"""

import json
import os
import re
import urllib.request

POSTS = [
    "DfNewqWiIVe",
    "DfKXVOHoJOa",
    "DfNpbgTAQ5j",
    "De9jBx2Mp-d",
    "DfNRm7oxQq8",
    "DfO0maoI2em",
    "DfO4gkKDZnX",
    "DfNqbqxEb6M",
    "DfMwbCUiLkO",
    "DfNX4-UgVdH",
]

HEADERS = {
    "User-Agent": "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
    "Accept-Language": "en-US,en;q=0.9",
}
AVATAR_DIR = "assets/images/avatar_posts"


def fetch(url: str) -> bytes:
    return urllib.request.urlopen(
        urllib.request.Request(url, headers=HEADERS), timeout=40
    ).read()


def strip_tags(fragment: str) -> str:
    fragment = re.sub(r"<br\s*/?>", "\n", fragment)
    fragment = re.sub(r"<[^>]+>", "", fragment)
    for entity, char in (
        ("&amp;", "&"),
        ("&#039;", "'"),
        ("&#39;", "'"),
        ("&quot;", '"'),
        ("&lt;", "<"),
        ("&gt;", ">"),
        ("&nbsp;", " "),
    ):
        fragment = fragment.replace(entity, char)
    return fragment.strip()


def parse(code: str) -> dict:
    url = f"https://www.instagram.com/p/{code}/embed/captioned/?hl=en"
    html = fetch(url).decode("utf-8", "ignore")

    handle = ""
    m = re.search(r'class="UsernameText">([^<]+)</span>', html)
    if m:
        handle = m.group(1).strip()

    verified = 'class="Sprite VerifiedSprite' in html

    avatar = ""
    for src in re.findall(r'<img[^>]+src="([^"]+)"', html):
        if "s150x150" in src:
            avatar = src.replace("&amp;", "&")
            break

    caption = ""
    m = re.search(r'class="Caption">(.*?)(?:<div class="CaptionComments"|</div>)', html, re.S)
    if m:
        raw = m.group(1)
        # drop the leading "handle" link, keep the text after the <br /><br />
        raw = re.sub(r'^.*?<br\s*/?>\s*<br\s*/?>', "", raw, flags=re.S)
        caption = strip_tags(raw)

    likes = 0
    m = re.search(r'class="SocialProof">.*?([\d.,]+)\s*likes?', html, re.S)
    if m:
        likes = int(re.sub(r"\D", "", m.group(1)) or 0)

    followers = 0
    m = re.search(r'class="FollowerCountText">([^<]+)</span>', html)
    if m:
        followers = parse_count(m.group(1).replace("followers", "").strip())

    posts = 0
    m = re.search(r"([\d,]+)\s*posts", re.sub(r"<[^>]+>", " ", html))
    if m:
        posts = int(re.sub(r"\D", "", m.group(1)) or 0)

    return {
        "code": code,
        "handle": handle,
        "verified": verified,
        "avatar": avatar,
        "caption": caption,
        "likes": likes,
        "followers": followers,
        "posts": posts,
    }


def parse_count(text: str) -> int:
    text = text.strip().replace(" ", "")
    multiplier = 1
    if text and text[-1].upper() in "KMB":
        multiplier = {"K": 1_000, "M": 1_000_000, "B": 1_000_000_000}[text[-1].upper()]
        text = text[:-1]
    try:
        return int(float(text.replace(",", "")) * multiplier)
    except ValueError:
        return 0


def main() -> None:
    os.makedirs(AVATAR_DIR, exist_ok=True)
    rows = []
    for code in POSTS:
        try:
            row = parse(code)
        except Exception as error:  # noqa: BLE001 - report and continue
            print(code, "PARSE ERROR", error)
            continue
        if not row["avatar"]:
            print(code, "NO AVATAR for", row["handle"])
        else:
            path = os.path.join(AVATAR_DIR, f"{row['handle']}.jpg")
            with open(path, "wb") as handle_file:
                handle_file.write(fetch(row["avatar"]))
            row["avatar_file"] = path
            row["avatar_bytes"] = os.path.getsize(path)
        rows.append(row)
        print(
            code,
            "|",
            row["handle"],
            "| verified:",
            row["verified"],
            "| likes:",
            row["likes"],
            "| followers:",
            row["followers"],
            "| posts:",
            row["posts"],
            "| caption:",
            row["caption"][:60].encode("ascii", "replace").decode(),
        )

    with open(".tmp/posts_scraped.json", "w", encoding="utf-8") as handle_file:
        json.dump(rows, handle_file, ensure_ascii=False, indent=1)
    print("rows:", len(rows))


if __name__ == "__main__":
    main()
