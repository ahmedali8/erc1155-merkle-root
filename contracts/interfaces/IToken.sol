// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IUSDT.sol";

interface IToken {
    /**
     * @dev Emitted when a amount of tokenId is minted.
     */
    event NFTMinted(uint8 indexed tokenId, uint32 amount, address indexed beneficiary);

    /**
     * @dev Emitted when `amount` is send from `from` to `to`.
     */
    event FundsTransferred(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Returns the name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the maximum supply.
     */
    function maxSupply() external view returns (uint32);

    /**
     * @dev Returns price of the token.
     */
    function price() external view returns (uint256);

    /**
     * @dev Returns usdt token instance.
     */
    function usdt() external view returns (IUSDT);

    /**
     * @dev Returns wallet address to recieve the funds.
     */
    function wallet() external view returns (address);

    /**
     * @dev Returns the total supply.
     */
    function totalSupply() external view returns (uint32);

    /**
     * @dev Returns boolean value of claimer address.
     */
    function claims(address) external view returns (bool);

    /**
     * @dev Returns the price for `_amount` of token.
     */
    function tokensPrice(uint32 _amount) external pure returns (uint256);

    /**
     * @dev Mints `_amount` of token and transfers to caller.
     *
     * Emits a {NFTMinted} and {FundsTransferred} events.
     */
    function mint(uint256 _value, uint32 _amount) external;

    /**
     * @dev Mints `_amount` of token and transfers to caller if exists in merkle root.
     *
     * Emits a {NFTMinted} event.
     */
    function claim(
        uint256 _index,
        uint256 _amount,
        bytes32[] memory _proof
    ) external;

    /**
     * @dev Mints `_amount` tokens and transfers to `_to`.
     *
     * Emits a {NFTMinted} event.
     *
     * Note that caller must be {owner}.
     */
    function freeMint(address _to, uint32 _amount) external;

    /**
     * @dev Sets the merkle root.
     *
     * Note that caller must be {owner}.
     *
     * Emits a {RootSet} event.
     */
    function setRoot(bytes32 _root, string memory _proofHash) external;
}
