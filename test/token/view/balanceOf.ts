import { BigNumber } from "@ethersproject/bignumber";
import { Zero } from "@ethersproject/constants";

import { toWei } from "../../../utils/format";
import { PRICE_FOR_ONE_NFT, USDT_DECIMALS } from "../../shared/constants";
import { expect } from "../../shared/expect";

export default function shouldBehaveLikeERC20BalanceOf(): void {
  context("when the account does not have an nft balance", function () {
    it("retrieves zero", async function () {
      const balance: BigNumber = await this.contracts.token.balanceOf(
        this.signers.addr1.address,
        "1"
      );
      expect(balance).to.equal(Zero);
    });
  });

  context("when the account has an nft balance", function () {
    beforeEach(async function () {
      // mint 200 usdt and approve token contract
      await this.contracts.usdt
        .connect(this.signers.addr1)
        .mint(this.signers.addr1.address, PRICE_FOR_ONE_NFT);
      await this.contracts.usdt
        .connect(this.signers.addr1)
        .approve(this.contracts.token.address, PRICE_FOR_ONE_NFT);

      // mint 1 nft
      await this.contracts.token.connect(this.signers.addr1).mint(PRICE_FOR_ONE_NFT, 1);
    });

    it("retrieves the correct balance", async function () {
      expect(await this.contracts.token.balanceOf(this.signers.addr1.address, 1)).to.be.equal(1);
    });
  });

  context("when addr1 and addr2 has 2000 usdt each", function () {
    it("retrieves the correct balance", async function () {
      expect(await this.contracts.usdt.balanceOf(this.signers.addr1.address)).to.be.equal(
        toWei("2000", USDT_DECIMALS)
      );
      expect(await this.contracts.usdt.balanceOf(this.signers.addr2.address)).to.be.equal(
        toWei("2000", USDT_DECIMALS)
      );
    });
  });
}
