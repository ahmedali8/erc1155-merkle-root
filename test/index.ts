import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, waffle } from "hardhat";

import type { Contracts, Signers } from "./shared/types";
import { testToken } from "./token/Token";

const { createFixtureLoader } = waffle;

describe("Unit tests", () => {
  before(async function () {
    this.contracts = {} as Contracts;
    this.signers = {} as Signers;

    const signers: SignerWithAddress[] = await ethers.getSigners();
    this.signers.owner = signers[0];
    this.signers.wallet = signers[1];
    this.signers.addr1 = signers[2];
    this.signers.addr2 = signers[3];
    this.signers.addr3 = signers[4];
    this.signers.accounts = signers.slice(5);

    this.loadFixture = createFixtureLoader();
  });

  testToken();
});
