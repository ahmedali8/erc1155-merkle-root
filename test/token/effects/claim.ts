import { keccak256 } from "@ethersproject/solidity";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";

import {
  MerkleDistributorInfo,
  parseBalanceMap,
} from "../../../scripts/merkleroot/parse-balance-map";
import { randomInteger } from "../../../utils/format";
import { TOKEN_ID } from "../../shared/constants";
import { OwnableErrors, TokenErrors } from "../../shared/errors";
import { expect } from "../../shared/expect";

export default function shouldBehaveLikeClaim(): void {
  context("when merkle tree is created with amount 1", function () {
    let caller: SignerWithAddress;
    let list: {
      address: string;
      amount: number;
    }[];

    let treeData: MerkleDistributorInfo;
    let root: string;
    let index: number;
    let amount: number;
    let proof: string[];
    let leaf: string;

    before(async function () {
      caller = this.signers.accounts[2];

      list = this.signers.accounts.map((account) => ({
        address: account.address,
        amount: 1,
      }));

      treeData = parseBalanceMap(list);

      root = treeData.merkleRoot;
      index = treeData.claims[caller.address].index;
      amount = parseInt(treeData.claims[caller.address].amount);
      proof = treeData.claims[caller.address].proof;

      leaf = keccak256(["uint256", "address", "uint256"], [index, caller.address, amount]);

      // log("treeData", treeData);
    });

    context("when non-owner sets root", function () {
      it("reverts", async function () {
        await expect(
          this.contracts.token.connect(this.signers.addr3).setRoot(root, "ipfsHash")
        ).to.be.revertedWith(OwnableErrors.NotOwner);
      });
    });

    context("when owner sets root", function () {
      // before won't work here
      beforeEach(async function () {
        await this.contracts.token.connect(this.signers.owner).setRoot(root, "ipfsHash");
      });

      it("retrieves root and proofHash", async function () {
        expect(await this.contracts.token.root()).to.equal(root);
        expect(await this.contracts.token.proofHash()).to.equal("ipfsHash");
      });

      it("retrieves result for proof and leaf", async function () {
        expect(await this.contracts.token.verify(proof, leaf)).to.equal(true);
      });
    });

    context("when invalid arguments are given to claim", function () {
      beforeEach(async function () {
        await this.contracts.token.connect(this.signers.owner).setRoot(root, "ipfsHash");
      });

      it("reverts with wrong index", async function () {
        await expect(
          this.contracts.token.connect(caller).claim(100, amount, proof)
        ).to.be.revertedWith(TokenErrors.InvalidProof);
      });

      it("reverts with wrong amount", async function () {
        await expect(
          this.contracts.token.connect(caller).claim(index, 23, proof)
        ).to.be.revertedWith(TokenErrors.InvalidProof);
      });

      it("reverts with wrong proof array", async function () {
        const invalidProof = [
          "0x838d10ace3a0ee1ad25535eae94ac4a7730141a1051a5fc2c97b402a84be1af8",
          "0x740fda1488c3f2289214c3444557361eb7c67ccca0968d40be6dc77936743bfb",
        ];

        await expect(
          this.contracts.token.connect(caller).claim(index, amount, invalidProof)
        ).to.be.revertedWith(TokenErrors.InvalidProof);
      });
    });

    context("when valid arguments are given to claim", function () {
      beforeEach(async function () {
        await this.contracts.token.connect(this.signers.owner).setRoot(root, "ipfsHash");
      });

      it("increases balance of claimer and total supply", async function () {
        const nftsToClaim = 1;
        await expect(this.contracts.token.connect(caller).claim(index, amount, proof))
          .to.emit(this.contracts.token, "NFTMinted")
          .withArgs(TOKEN_ID, nftsToClaim, caller.address);
        expect(await this.contracts.token.balanceOf(caller.address, TOKEN_ID)).to.equal(
          nftsToClaim
        );
        expect(await this.contracts.token.totalSupply()).to.equal(nftsToClaim);
      });
    });
  });

  context("when merkle tree is created with random amounts", function () {
    let totalAmount: number = 0;
    let list: {
      address: string;
      amount: number;
    }[];

    let treeData: MerkleDistributorInfo;
    let root: string;

    before(async function () {
      list = this.signers.accounts.map((account) => {
        const randNum = randomInteger(1, 10);

        return {
          address: account.address,
          amount: randNum,
        };
      });

      treeData = parseBalanceMap(list);

      root = treeData.merkleRoot;
    });

    context("when each signer from list claims", function () {
      beforeEach(async function () {
        await this.contracts.token.connect(this.signers.owner).setRoot(root, "ipfsHash");
      });

      it("claims from each signer and reverts if try to claim twice", async function () {
        for (let i = 0; i < list.length; i++) {
          const { address, amount } = list[i];
          // console.log(`i: ${i}, address: ${address}, amount: ${amount}`);

          const signer = await ethers.getSigner(address);
          const index = treeData.claims[signer.address].index;
          const amountFromTree = treeData.claims[signer.address].amount;
          const proof = treeData.claims[signer.address].proof;

          expect(amountFromTree).to.equal(amount.toString());

          // claim
          await expect(this.contracts.token.connect(signer).claim(index, amount, proof)).to.emit(
            this.contracts.token,
            "NFTMinted"
          );
          expect(await this.contracts.token.balanceOf(signer.address, TOKEN_ID)).to.equal(amount);

          totalAmount = totalAmount + amount;
        }

        expect(await this.contracts.token.totalSupply()).to.equal(totalAmount);

        await expect(
          this.contracts.token
            .connect(this.signers.accounts[3])
            .claim(
              treeData.claims[this.signers.accounts[3].address].index,
              treeData.claims[this.signers.accounts[3].address].amount,
              treeData.claims[this.signers.accounts[3].address].proof
            )
        ).to.be.revertedWith(TokenErrors.AlreadyClaimed);
      });
    });
  });
}
