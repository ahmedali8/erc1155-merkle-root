// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./MerkleProofVerify.sol";
import "./interfaces/IToken.sol";

contract Token is IToken, Ownable, ERC1155, MerkleProofVerify {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IToken
    string public constant override name = "Token NFT";

    /// @inheritdoc IToken
    string public constant override symbol = "TNFT";

    /// @inheritdoc IToken
    uint32 public constant override maxSupply = 300;

    /// @inheritdoc IToken
    uint256 public constant override price = 200 * 1e6; // 200 usdt

    /// @inheritdoc IToken
    IUSDT public immutable override usdt;

    /// @inheritdoc IToken
    address public immutable override wallet;

    /// @inheritdoc IToken
    uint32 public override totalSupply = 0;

    /// @inheritdoc IToken
    /// @dev mapping claimer address to bool value
    mapping(address => bool) public override claims;

    /// INTERNAL STORAGE ///

    ///@dev URI of the token.
    string internal _uri = "ipfs://QmQFkLSQysj94s5GvTHPyzTxrawwtjgiiYS2TBLgrvw8CW/6338";

    /// CONSTRUCTOR ///

    /// @notice Set uri in ERC1155 and address of usdt token.
    ///
    /// @param _usdt - usdt token address.
    /// @param _wallet - address to receive funds.
    constructor(address _usdt, address _wallet) ERC1155("") {
        usdt = IUSDT(_usdt);
        wallet = _wallet;
    }

    /// PUBLIC VIEW/PURE FUNCTIONS ///

    /// @inheritdoc ERC1155
    function uri(uint256 _id) public view virtual override returns (string memory) {
        return (bytes(_uri).length > 0) ? _uri : "";
    }

    /// @inheritdoc IToken
    function tokensPrice(uint32 _amount) public pure override returns (uint256) {
        return uint256(_amount * price);
    }

    /// EXTERNAL NON-VIEW/PURE FUNCTIONS ///

    /// @inheritdoc IToken
    function mint(uint256 _value, uint32 _amount) external override {
        if (_value != tokensPrice(_amount)) revert InvalidPrice();

        // transfers usdt to this address
        usdt.transferFrom(_msgSender(), address(this), _value);
        // transfers usdt to wallet now
        _transferFunds(_value);

        _mintInternal(_msgSender(), _amount);
    }

    /// @inheritdoc IToken
    function claim(
        uint256 _index,
        uint256 _amount,
        bytes32[] memory _proof
    ) external override {
        bytes32 _leaf = keccak256(abi.encodePacked(_index, _msgSender(), _amount));
        if (!verify(_proof, _leaf)) revert InvalidProof();
        if (claims[_msgSender()]) revert AlreadyClaimed();

        claims[_msgSender()] = true;

        _mintInternal(_msgSender(), uint32(_amount));
    }

    /// @inheritdoc IToken
    function freeMint(address _to, uint32 _amount) external override onlyOwner {
        _mintInternal(_to, _amount);
    }

    /// @inheritdoc IToken
    function setRoot(bytes32 _root, string memory _proofHash) external override onlyOwner {
        _setRoot(_root, _proofHash);
    }

    /// INTERNAL NON-VIEW/PURE FUNCTIONS ///

    /// @notice Transfer funds to {wallet}.
    ///
    /// @dev Emits a {FundsTransferred} event indicating transfer of funds.
    ///
    /// @param _value - usdt amount.
    function _transferFunds(uint256 _value) internal {
        address _wallet = wallet;
        usdt.transfer(_wallet, _value);
        emit FundsTransferred(_msgSender(), _wallet, _value);
    }

    /// @notice Mint new tokens.
    ///
    /// @dev Emits a {NFTMinted} event indicating transfer of nft to recipient.
    ///
    /// @param _to - recipient address.
    /// @param _amount - amount to mint.
    function _mintInternal(address _to, uint32 _amount) internal {
        if (_amount > 10) revert MaxTenMintsPerTxn();
        if (totalSupply + _amount > maxSupply) revert MaxSupplyLimitReached();

        uint8 _id = 1;
        _mint(_to, uint256(_id), uint256(_amount), "");
        totalSupply = totalSupply + _amount;

        emit NFTMinted(_id, _amount, _to);
    }
}
