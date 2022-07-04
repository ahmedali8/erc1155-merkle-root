import { TOKEN_ID } from "../../shared/constants";
import { OwnableErrors } from "../../shared/errors";
import { expect } from "../../shared/expect";

export default function shouldBehaveLikeFreeMint(): void {
  context("when non-owner calls freeMint", function () {
    it("reverts", async function () {
      await expect(
        this.contracts.token
          .connect(this.signers.addr1)
          .freeMint(this.signers.accounts[0].address, 1)
      ).to.be.revertedWith(OwnableErrors.NotOwner);
    });
  });

  context("when owner mints 5 tokens for accounts[0]", function () {
    const tokensToMint: number = 5;

    beforeEach(async function () {
      await this.contracts.token
        .connect(this.signers.owner)
        .freeMint(this.signers.accounts[0].address, tokensToMint);
    });

    it("increases balance of accounts[0]", async function () {
      expect(
        await this.contracts.token.balanceOf(this.signers.accounts[0].address, TOKEN_ID)
      ).to.equal(tokensToMint);
    });

    it("increases totalSupply", async function () {
      expect(await this.contracts.token.totalSupply()).to.equal(tokensToMint);
    });
  });
}
