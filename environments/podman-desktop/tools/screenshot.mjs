// Saves a screenshot of the running Podman Desktop (over the Chrome DevTools Protocol, port 9222):
// the whole window, or one element. The agent then hands the file to `macaron-agent attach`.
//
//   node "$MACARON_ENV/tools/screenshot.mjs" --out /tmp/editor.png [--selector 'CSS selector']
import { parseArgs } from "node:util";
import { chromium } from "playwright";

const { values } = parseArgs({ options: { out: { type: "string" }, selector: { type: "string" } } });
if (values.out === undefined) {
  console.error("usage: screenshot.mjs --out FILE.png [--selector CSS]");
  process.exit(2);
}

const browser = await chromium.connectOverCDP("http://127.0.0.1:9222");
try {
  const page = browser
    .contexts()
    .flatMap((context) => context.pages())
    .find((candidate) => !candidate.url().startsWith("devtools://"));
  if (page === undefined) throw new Error("no Podman Desktop window: is it running? (bash \"$MACARON_ENV/podman-desktop.sh\")");
  if (values.selector === undefined) await page.screenshot({ path: values.out });
  else await page.locator(values.selector).first().screenshot({ path: values.out, timeout: 10_000 });
  console.log(`saved ${values.out}`);
} finally {
  // Disconnects; Podman Desktop keeps running.
  await browser.close();
}
process.exit(0);
