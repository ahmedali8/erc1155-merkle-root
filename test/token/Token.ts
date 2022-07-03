import { toWei } from "../../utils/format";
import { USDT_DECIMALS } from "../shared/constants";
import { tokenFixture } from "../shared/fixtures";
import { shouldBehaveLikeToken } from "./Token.behavior";

export function testToken(): void {
  describe("Token", function () {
    beforeEach(async function () {
      const { usdt, token } = await this.loadFixture(tokenFixture);
      this.contracts.usdt = usdt;
      this.contracts.token = token;

      // mint 2000 usdt for addr1 and addr2
      await this.contracts.usdt.mint(this.signers.addr1.address, toWei("2000", USDT_DECIMALS));
      await this.contracts.usdt.mint(this.signers.addr2.address, toWei("2000", USDT_DECIMALS));
    });
    shouldBehaveLikeToken();
  });
}
