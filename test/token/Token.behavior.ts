import shouldBehaveLikeClaim from "./effects/claim";
import shouldBehaveLikeMint from "./effects/mint";
import shouldBehaveLikeERC20BalanceOf from "./view/balanceOf";
import shouldBehaveLikeMaxSupplyGetter from "./view/maxSupply";
import shouldBehaveLikeNameGetter from "./view/name";
import shouldBehaveLikeOwnerGetter from "./view/owner";
import shouldBehaveLikePriceGetter from "./view/price";
import shouldBehaveLikeSymbolGetter from "./view/symbol";
import shouldBehaveLikeTotalSupplyGetter from "./view/totalSupply";
import shouldBehaveLikeURIGetter from "./view/uri";
import shouldBehaveLikeUSDTGetter from "./view/usdt";
import shouldBehaveLikeWalletGetter from "./view/wallet";

export function shouldBehaveLikeToken(): void {
  describe("View Functions", function () {
    describe("name", function () {
      shouldBehaveLikeNameGetter();
    });

    describe("symbol", function () {
      shouldBehaveLikeSymbolGetter();
    });

    describe("owner", function () {
      shouldBehaveLikeOwnerGetter();
    });

    describe("wallet", function () {
      shouldBehaveLikeWalletGetter();
    });

    describe("maxSupply", function () {
      shouldBehaveLikeMaxSupplyGetter();
    });

    describe("totalSupply", function () {
      shouldBehaveLikeTotalSupplyGetter();
    });

    describe("uri", function () {
      shouldBehaveLikeURIGetter();
    });

    describe("price", function () {
      shouldBehaveLikePriceGetter();
    });

    describe("usdt", function () {
      shouldBehaveLikeUSDTGetter();
    });

    describe("balanceOf", function () {
      shouldBehaveLikeERC20BalanceOf();
    });
  });

  describe("Effects Functions", function () {
    describe("mint", function () {
      shouldBehaveLikeMint();
    });

    describe("claim", function () {
      shouldBehaveLikeClaim();
    });
  });
}
