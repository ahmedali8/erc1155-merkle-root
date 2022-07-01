// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./MerkleProofVerify.sol";
import "./interfaces/IToken.sol";
import "./Errors.sol";

contract Token is IToken, Ownable, ERC1155, MerkleProofVerify {
    /**
     * @dev See {IToken-name}
     */
    string public constant override name = "Token NFT";

    /**
     * @dev See {IToken-symbol}
     */
    string public constant override symbol = "TNFT";

    /**
     * @dev See {IToken-maxSupply}
     */
    uint32 public constant override maxSupply = 300;

    /**
     * @dev See {IToken-price}
     */
    uint256 public constant override price = 200 * 1e6; // 200 usdt

    /**
     * @dev See {IToken-price}
     */
    IUSDT public immutable override usdt;

    /**
     * @dev See {IToken-wallet}
     */
    address public immutable override wallet;

    /**
     * @dev See {IToken-totalSupply}
     */
    uint32 public override totalSupply = 0;

    /**
     * @dev URI of the token.
     */
    string internal _uri = "ipfs://QmQFkLSQysj94s5GvTHPyzTxrawwtjgiiYS2TBLgrvw8CW/6338";

    /**
     * @dev See {IToken-claims}
     * mapping claimer address to bool value
     */
    mapping(address => bool) public override claims;

    /**
     * @dev Set uri in ERC1155 and usdt token.
     *
     * @param _usdt - usdt token address.
     * @param _wallet - address to receive funds.
     */
    constructor(address _usdt, address _wallet) ERC1155("") {
        usdt = IUSDT(_usdt);
        wallet = _wallet;
    }

    /**
     * @dev See {ERC1155-uri}
     */
    function uri(uint256 _id) public view virtual override returns (string memory) {
        return (bytes(_uri).length > 0) ? _uri : "";
    }

    /**
     * @dev See {IToken-tokensPrice}.
     */
    function tokensPrice(uint32 _amount) public pure override returns (uint256) {
        return uint256(_amount * price);
    }

    /**
     * @dev See {IToken-mint}.
     *
     * Emits a {NFTMinted} event indicating the mint of amount of a new NFT.
     *
     * @param _amount - no of tokens `caller` wants to mint.
     *
     * Requirements:
     *
     * - `_value` must be equal to correct tokenPrice.
     * - `_amount` must be max 3 per txn.
     * - max supply must not be exceeded.
     */
    function mint(uint256 _value, uint32 _amount) external override {
        if (_value != tokensPrice(_amount)) revert InvalidPrice();

        // transfers usdt to this address
        usdt.transferFrom(_msgSender(), address(this), _value);
        // transfers usdt to wallet now
        _transferFunds(_value);

        _mintPrivate(_msgSender(), _amount);
    }

    /**
     * @dev See {IToken-claim}.
     *
     * Emits a {NFTMinted} event indicating the mint of amount of a new NFT.
     *
     * @param _index uint256 index of account.
     * @param _amount uint256 amount to be claimed.
     * @param _proof bytes32[] proof of merkle root.
     *
     * Requirements:
     *
     * - `_index`, `_amount` and `_proof` must be valid from merkle root.
     */
    function claim(
        uint256 _index,
        uint256 _amount,
        bytes32[] memory _proof
    ) external override {
        bytes32 _leaf = keccak256(abi.encodePacked(_index, _msgSender(), _amount));
        if (!verify(_proof, _leaf)) revert InvalidProof();
        if (claims[_msgSender()]) revert AlreadyClaimed();

        claims[_msgSender()] = true;

        _mintPrivate(_msgSender(), uint32(_amount));
    }

    /**
     * @dev See {IToken-freeMint}.
     *
     * Emits a {NFTMinted} event indicating the mint of amount of a new NFT.
     *
     * @param _to - recipient address.
     * @param _amount - amount to mint.
     *
     * Requirements:
     *
     * - caller must be {owner}.
     */
    function freeMint(address _to, uint32 _amount) external override onlyOwner {
        _mintPrivate(_to, _amount);
    }

    /**
     * @dev See {IToken-setRoot}.
     *
     * Emits a {RootSet} event indicating update of merkle root hash.
     *
     * @param _root - markle root
     * @param _proofHash - ipfs hash containing json file of proofs.
     *
     * Requirements:
     *
     * - caller must be {owner}.
     * - `_root` must be valid.
     */
    function setRoot(bytes32 _root, string memory _proofHash) public override onlyOwner {
        _setRoot(_root, _proofHash);
    }

    /**
     * @dev Internal function to mint new tokens.
     *
     * Emits a {NFTMinted} event indicating transfer of nft to recipient.
     *
     * @param _to - recipient address.
     * @param _amount - amount to mint.
     */
    function _mintPrivate(address _to, uint32 _amount) private {
        if (_amount > 10) revert MaxTenMintsPerTxn();
        if (totalSupply + _amount > maxSupply) revert MaxSupplyLimitReached();

        uint8 _id = 1;
        _mint(_to, uint256(_id), uint256(_amount), "");
        totalSupply = totalSupply + _amount;

        emit NFTMinted(_id, _amount, _to);
    }

    /**
     * @dev Internal function to transfer funds to {wallet}.
     *
     * Emits a {FundsTransferred} event indicating transfer of funds.
     *
     * @param _value - usdt amount.
     */
    function _transferFunds(uint256 _value) internal {
        address _wallet = wallet;
        usdt.transfer(_wallet, _value);
        emit FundsTransferred(_msgSender(), _wallet, _value);
    }
}
