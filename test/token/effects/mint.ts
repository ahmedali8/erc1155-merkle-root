import { MaxUint256 } from "@ethersproject/constants";

import { toWei } from "../../../utils/format";
import { TOKEN_ID, USDT_DECIMALS } from "../../shared/constants";
import { TokenErrors, USDTErrors } from "../../shared/errors";
import { expect } from "../../shared/expect";
import { tokenPrice } from "../../shared/utils";

export default function shouldBehaveLikeMint(): void {
  context("when usdt is not approved", function () {
    it("reverts", async function () {
      const price = tokenPrice();
      await expect(
        this.contracts.token.connect(this.signers.addr1).mint(price, 1)
      ).to.be.revertedWith(USDTErrors.TransferAmountExceedsAllowance);
    });
  });

  context("when usdt is approved", function () {
    // addr1 approves max uint256 usdt to token contract
    beforeEach(async function () {
      await this.contracts.usdt
        .connect(this.signers.addr1)
        .approve(this.contracts.token.address, MaxUint256);
    });

    context("when user mints more than 10 nfts per txn", function () {
      it("reverts", async function () {
        const nftsToMint = 11;
        const price = tokenPrice(nftsToMint);

        // mint 1000 more to addr1
        await this.contracts.usdt
          .connect(this.signers.addr1)
          .mint(this.signers.addr1.address, toWei("1000", USDT_DECIMALS));
        expect(await this.contracts.usdt.balanceOf(this.signers.addr1.address)).to.equal(
          toWei("3000", USDT_DECIMALS)
        );

        // mint NFT
        await expect(
          this.contracts.token.connect(this.signers.addr1).mint(price, nftsToMint)
        ).to.be.revertedWith(TokenErrors.MaxTenMintsPerTxn);
      });
    });

    context("when the mint results into an overflow", function () {
      it("reverts", async function () {
        const nftsToMint = 11;
        const price = tokenPrice(nftsToMint);

        // overflow
        await expect(
          this.contracts.token.connect(this.signers.addr1).mint(price, MaxUint256)
        ).to.be.reverted;
      });
    });

    context("when user mints 10 tokens", function () {
      const nftsToMint = 10;
      const price = tokenPrice(nftsToMint);

      it("increases the balance of the user", async function () {
        await this.contracts.token.connect(this.signers.addr1).mint(price, nftsToMint);
        expect(await this.contracts.token.balanceOf(this.signers.addr1.address, TOKEN_ID)).to.equal(
          nftsToMint
        );
      });

      it("increases the total supply", async function () {
        const preTotalSupply: number = await this.contracts.token.totalSupply();
        await this.contracts.token.connect(this.signers.addr1).mint(price, nftsToMint);
        const postTotalSupply: number = await this.contracts.token.totalSupply();
        expect(postTotalSupply).to.equal(preTotalSupply + nftsToMint);
      });

      it("emits a NFTMinted and FundsTransferred events", async function () {
        await expect(this.contracts.token.connect(this.signers.addr1).mint(price, nftsToMint))
          .to.emit(this.contracts.token, "NFTMinted")
          .withArgs(TOKEN_ID, nftsToMint, this.signers.addr1.address)
          .to.emit(this.contracts.token, "FundsTransferred")
          .withArgs(this.signers.addr1.address, this.signers.wallet.address, price);
      });
    });
  });
}
