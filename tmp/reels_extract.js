/* Run from the app's public folder with a real Chromium/WebFetch that can
   render Instagram pages. This script only browses the current page,
   detects Arabic vs English caption text on each reel article, and logs
   a ranked list so the next step can pick 10 English reels.
*/

(() => {
  const ARABIC = /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]/;
  const articles = Array.from(document.querySelectorAll('article'));
  const rows = [];
  for (const article of articles) {
    const text = article.innerText.trim();
    if (!text) continue;
    const isArabic = ARabic.test(text);
    rows.push({
      arabic: isArabic,
      head: text.slice(0, 220).replace(/\s+/g, ' '),
    });
  }
  const english = rows.filter(r => !r.arabic);
  const arabic = rows.filter(r => r.arabic);
  window.__reelsClassification = {
    englishCount: english.length,
    arabicCount: arabic.length,
    englishHeads: english.map(r => r.head),
    arabicHeads: arabic.map(r => r.head),
  };
  console.log(JSON.stringify(window.__reelsClassification, null, 2));
  return window.__reelsClassification;
})();
