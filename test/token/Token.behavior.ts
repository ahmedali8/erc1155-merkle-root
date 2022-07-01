import { expect } from "chai";

import { log } from "../../utils/log";

export function shouldBehaveLike(): void {
  it("should return the usdt contract", async function () {
    // log("usdt", this.usdt);
    // log("signers", this.signers);
    log("token", this.token);
  });
}
