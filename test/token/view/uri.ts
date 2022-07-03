import { expect } from "../../shared/expect";

export default function shouldBehaveLikeURIGetter(): void {
  it("retrieves the uri", async function () {
    const uri: string = await this.contracts.token.uri(1);
    expect(uri).to.equal("ipfs://QmQFkLSQysj94s5GvTHPyzTxrawwtjgiiYS2TBLgrvw8CW/6338");
  });
}
