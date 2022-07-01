import { getAddress, isAddress } from "@ethersproject/address";
import { BigNumber } from "@ethersproject/bignumber";

import { toBN } from "../../utils/format";
import BalanceTree from "./balance-tree";

export interface MerkleDistributorInfo {
  merkleRoot: string;
  tokenTotal: string;
  claims: {
    [account: string]: {
      index: number;
      amount: string;
      proof: string[];
    };
  };
}

type OldFormat = { [account: string]: number | string };
type NewFormat = { address: string; amount: string | number };

export function parseBalanceMap(
  balances: OldFormat | NewFormat[]
): MerkleDistributorInfo {
  const balancesInNewFormat: NewFormat[] = Array.isArray(balances)
    ? balances
    : Object.keys(balances).map(
        (account): NewFormat => ({
          address: account,
          amount: balances[account],
        })
      );

  const dataByAddress = balancesInNewFormat.reduce<{
    [address: string]: { amount: BigNumber };
  }>((memo, { address: account, amount }) => {
    if (!isAddress(account)) {
      throw new Error(`Found invalid address: ${account}`);
    }
    const parsed = getAddress(account);
    if (memo[parsed]) throw new Error(`Duplicate address: ${parsed}`);

    memo[parsed] = { amount: toBN(amount.toString()) };
    return memo;
  }, {});

  const sortedAddresses = Object.keys(dataByAddress).sort();

  // construct a tree
  const tree = new BalanceTree(
    sortedAddresses.map((address) => ({
      account: address,
      amount: dataByAddress[address].amount,
    }))
  );

  // generate claims
  const claims = sortedAddresses.reduce<{
    [address: string]: { amount: string; index: number; proof: string[] };
  }>((memo, address, index) => {
    const { amount } = dataByAddress[address];
    memo[address] = {
      index,
      amount: amount.toString(), // already in 8 decimals
      proof: tree.getProof(index, address, amount),
    };
    return memo;
  }, {});

  const tokenTotal: BigNumber = sortedAddresses.reduce<BigNumber>(
    (memo, key) => memo.add(dataByAddress[key].amount),
    BigNumber.from(0)
  );

  return {
    merkleRoot: tree.getHexRoot(),
    tokenTotal: tokenTotal.toString(),
    claims,
  };
}
