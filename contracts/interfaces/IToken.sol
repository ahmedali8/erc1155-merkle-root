// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IUSDT.sol";

interface IToken {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when invalid price is given to mint.
    error InvalidPrice();

    /// @notice Emitted when invalid proof is given to claim.
    error InvalidProof();

    /// @notice Emitted when invalid price is given for mint.
    error AlreadyClaimed();

    /// @notice Emitted when invalid price is given for mint.
    error URIAlreadySet();

    /// @notice Emitted when invalid price is given for mint.
    error MaxTenMintsPerTxn();

    /// @notice Emitted when invalid price is given for mint.
    error MaxSupplyLimitReached();

    /// EVENTS ///

    /// @notice Emitted when a amount of tokenId is minted.
    /// @param tokenId The tokenId of the NFT.
    /// @param amount The amount of the NFTs.
    /// @param beneficiary The caller minting the NFT.
    event NFTMinted(uint8 indexed tokenId, uint32 amount, address indexed beneficiary);

    /// @notice Emitted when `amount` is send from `from` to `to`.
    /// @param from The address of from.
    /// @param to The address of to.
    /// @param amount The amount of the NFTs.
    event FundsTransferred(address indexed from, address indexed to, uint256 amount);

    /// VIEW/PURE FUNCTIONS ///

    /// @notice Returns the name.
    function name() external view returns (string memory);

    /// @notice Returns the symbol.
    function symbol() external view returns (string memory);

    /// @notice Returns the maximum supply.
    function maxSupply() external view returns (uint32);

    /// @notice Returns price of the token.
    function price() external view returns (uint256);

    /// @notice Returns usdt token instance.
    function usdt() external view returns (IUSDT);

    /// @notice Returns wallet address to recieve the funds.
    function wallet() external view returns (address);

    /// @notice Returns the total supply.
    function totalSupply() external view returns (uint32);

    /// @notice Returns boolean value of claimer address.
    function claims(address) external view returns (bool);

    /// @notice Returns the price for `_amount` of token.
    function tokensPrice(uint32 _amount) external pure returns (uint256);

    /// NON-VIEW/PURE FUNCTIONS ///

    /// @notice Mints `_amount` of token and transfers to caller.
    ///
    /// @dev Emits a {NFTMinted} event indicating the mint of amount of a new NFT.
    /// @dev Emits a {FundsTransferred} event indicating funds transfer.
    ///
    /// Requirements:
    ///
    /// - `_value` must be equal to correct tokenPrice.
    /// - `_amount` must be max 3 per txn.
    /// - max supply must not be exceeded.
    ///
    /// @param _value The value of tokens in usdt.
    /// @param _amount The no of tokens `caller` wants to mint.
    function mint(uint256 _value, uint32 _amount) external;

    /// @notice Mints `_amount` of token and transfers to caller if exists in merkle root.
    ///
    /// @dev Emits a {NFTMinted} event indicating the mint of amount of a new NFT.
    ///
    /// Requirements:
    ///
    /// - `_index`, `_amount` and `_proof` must be valid from merkle root.
    ///
    /// @param _index uint256 index of account.
    /// @param _amount uint256 amount to be claimed.
    /// @param _proof bytes32[] proof of merkle root.
    function claim(
        uint256 _index,
        uint256 _amount,
        bytes32[] memory _proof
    ) external;

    /// @notice Mints `_amount` tokens and transfers to `_to`.
    ///
    /// @dev Emits a {NFTMinted} event indicating the mint of amount of a new NFT.
    ///
    /// Requirements:
    ///
    /// - caller must be {owner}.
    ///
    /// @param _to - recipient address.
    /// @param _amount - amount to mint.
    function freeMint(address _to, uint32 _amount) external;

    /// @notice Sets the merkle root.
    ///
    /// @dev Emits a {RootSet} event indicating update of merkle root hash.
    ///
    /// Requirements:
    ///
    /// - caller must be {owner}.
    /// - `_root` must be valid.
    ///
    /// @param _root - markle root
    /// @param _proofHash - ipfs hash containing json file of proofs.
    function setRoot(bytes32 _root, string memory _proofHash) external;
}
