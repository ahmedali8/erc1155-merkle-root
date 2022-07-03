import { BigNumber } from "@ethersproject/bignumber";

import { PRICE_FOR_ONE_NFT } from "./constants";

export const tokenPrice = (amount: number = 1): BigNumber => {
  const price = PRICE_FOR_ONE_NFT.mul(amount);
  return price;
};
