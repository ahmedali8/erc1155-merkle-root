import { ethers } from "hardhat";

import { toWei } from "../utils/format";
import { verifyContract } from "../utils/verify";

async function main() {
  const { chainId } = await ethers.provider.getNetwork();

  const USDT_CONTRACT = "";
  const WALLET_ADDRESS = "";

  const contractName = "Token";
  const contractPath = `contracts/${contractName}.sol:${contractName}`;
  const contractAddress = "";
  const args: any[] = [USDT_CONTRACT, WALLET_ADDRESS];

  // You don't want to verify on localhost
  if (chainId != 31337 && chainId != 1337) {
    await verifyContract({
      contractPath,
      contractAddress,
      args,
    });
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.log(error);
    process.exit(1);
  });
