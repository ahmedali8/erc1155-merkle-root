import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { loadFixture } from "ethereum-waffle";
import { artifacts, ethers, waffle } from "hardhat";
import type { Artifact } from "hardhat/types";

import { TestUSDT, Token } from "../../src/types";

export async function usdtFixture(): Promise<{ usdt: TestUSDT }> {
  const signers = await ethers.getSigners();
  const deployer: SignerWithAddress = signers[0];

  const usdtArtifact: Artifact = await artifacts.readArtifact("TestUSDT");
  const usdt: TestUSDT = <TestUSDT>await waffle.deployContract(deployer, usdtArtifact, []);
  return { usdt };
}

export async function tokenFixture(): Promise<{ usdt: TestUSDT; token: Token }> {
  const signers = await ethers.getSigners();
  const deployer: SignerWithAddress = signers[0];
  const wallet: SignerWithAddress = signers[1];

  const { usdt } = await loadFixture(usdtFixture);

  const tokenArtifact: Artifact = await artifacts.readArtifact("Token");
  const token: Token = <Token>(
    await waffle.deployContract(deployer, tokenArtifact, [usdt.address, wallet.address])
  );

  return { usdt, token };
}
