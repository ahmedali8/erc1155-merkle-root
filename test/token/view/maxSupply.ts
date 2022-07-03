import { expect } from "../../shared/expect";

export default function shouldBehaveLikeMaxSupplyGetter(): void {
  it("retrieves the max supply", async function () {
    const maxSupply: number = await this.contracts.token.maxSupply();
    expect(maxSupply).to.equal(300);
  });
}
