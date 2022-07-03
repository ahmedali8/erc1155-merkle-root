import { BigNumber } from "@ethersproject/bignumber";

import { PRICE_FOR_ONE_NFT } from "../../shared/constants";
import { expect } from "../../shared/expect";

export default function shouldBehaveLikePriceGetter(): void {
  it("retrieves the price", async function () {
    const price: BigNumber = await this.contracts.token.price();
    expect(price).to.equal(PRICE_FOR_ONE_NFT);
  });
}
