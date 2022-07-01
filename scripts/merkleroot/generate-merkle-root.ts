import { Command } from "commander";
import path from "path";

import { parseFile, writeJSONFile } from "../../utils/files";
import { parseBalanceMap } from "./parse-balance-map";

const program = new Command();
program
  .version("0.0.0")
  .requiredOption(
    "-ji, --jsoninput <path>",
    "input JSON file location containing a map of account addresses to string balances"
  )
  .requiredOption(
    "-on, --outputname <name>",
    "input name for json tree file to be created"
  );
program.parse(process.argv);

async function main() {
  const json = await parseFile(program.jsoninput);
  console.log("json >>> ", json);
  if (typeof json !== "object") throw new Error("Invalid JSON");

  const data = parseBalanceMap(json);

  console.log("data >>> ", data);

  await writeJSONFile(
    path.join(process.cwd(), `./generated/${program.outputname}.json`),
    data
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.log(error);
    process.exit(1);
  });
