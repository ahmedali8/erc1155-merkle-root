import { expect } from "../../shared/expect";

export default function shouldBehaveLikeUSDTGetter(): void {
  it("retrieves the usdt", async function () {
    const usdt: string = await this.contracts.token.usdt();
    expect(usdt).to.equal(this.contracts.usdt.address);
  });
}
