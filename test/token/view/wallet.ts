import { expect } from "../../shared/expect";

export default function shouldBehaveLikeWalletGetter(): void {
  it("retrieves the wallet", async function () {
    const wallet: string = await this.contracts.token.wallet();
    expect(wallet).to.equal(this.signers.wallet.address);
  });
}
