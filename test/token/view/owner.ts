import { expect } from "../../shared/expect";

export default function shouldBehaveLikeOwnerGetter(): void {
  it("retrieves the owner", async function () {
    const owner: string = await this.contracts.token.owner();
    expect(owner).to.equal(this.signers.owner.address);
  });
}
