import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import type { Fixture } from "ethereum-waffle";

import type { TestUSDT, Token } from "../src/types";

declare module "mocha" {
  export interface Context {
    usdt: TestUSDT;
    token: Token;
    loadFixture: <T>(fixture: Fixture<T>) => Promise<T>;
    signers: Signers;
  }
}

export interface Signers {
  owner: SignerWithAddress;
  wallet: SignerWithAddress;
  addr1: SignerWithAddress;
  addr2: SignerWithAddress;
  addr3: SignerWithAddress;
  accounts: SignerWithAddress[];
}