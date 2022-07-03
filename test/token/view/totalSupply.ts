import { expect } from "../../shared/expect";

export default function shouldBehaveLikeTotalSupplyGetter(): void {
  it("retrieves the totalSupply", async function () {
    const totalSupply: number = await this.contracts.token.totalSupply();
    expect(totalSupply).to.equal(0);
  });
}
