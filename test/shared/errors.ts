export enum TokenErrors {
  InvalidRoot = "InvalidRoot()",
  InvalidPrice = "InvalidPrice()",
  InvalidProof = "InvalidProof()",
  AlreadyClaimed = "AlreadyClaimed()",
  URIAlreadySet = "URIAlreadySet()",
  MaxTenMintsPerTxn = "MaxTenMintsPerTxn()",
  MaxSupplyLimitReached = "MaxSupplyLimitReached()",
}

export enum OwnableErrors {
  NotOwner = "Ownable: caller is not the owner",
}

export enum USDTErrors {
  TransferAmountExceedsAllowance = "ERC20: transfer amount exceeds allowance",
}
