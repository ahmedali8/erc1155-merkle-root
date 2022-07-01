import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { artifacts, ethers, waffle } from "hardhat";
import type { Artifact } from "hardhat/types";

import type { TestUSDT, Token } from "../../src/types";
import { Signers } from "../types";
import { shouldBehaveLike } from "./Token.behavior";

describe("Unit tests", () => {
  before(async function () {
    this.signers = {} as Signers;

    const signers: SignerWithAddress[] = await ethers.getSigners();
    this.signers.owner = signers[0];
    this.signers.wallet = signers[1];
    this.signers.addr1 = signers[2];
    this.signers.addr2 = signers[3];
    this.signers.addr3 = signers[4];
    this.signers.accounts = signers.slice(5);
  });

  describe("Token", function () {
    beforeEach(async function () {
      const usdtArtifact: Artifact = await artifacts.readArtifact("TestUSDT");
      this.usdt = <TestUSDT>await waffle.deployContract(this.signers.owner, usdtArtifact, []);

      const tokenArtifact: Artifact = await artifacts.readArtifact("Token");
      this.token = <Token>(
        await waffle.deployContract(this.signers.owner, tokenArtifact, [
          this.usdt.address,
          this.signers.wallet.address,
        ])
      );
    });

    shouldBehaveLike();
  });
});
