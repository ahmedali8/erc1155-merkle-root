// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Merkle } from "murky/Merkle.sol";
import { Token } from "contracts/Token.sol";
import { TestUSDT } from "contracts/test/TestUSDT.sol";
import { Utils } from "./utils/Utils.sol";

contract BaseTest is Utils {
    // constants
    uint256 internal constant USDT_DECIMALS = 6;

    // contracts
    Token internal token;
    TestUSDT internal usdt;

    // accounts
    address payable internal owner;
    address payable internal wallet;
    address payable internal addr1;
    address payable internal addr2;
    address payable internal addr3;
    address payable[] internal accounts;

    // token events
    event NFTMinted(uint8 indexed tokenId, uint32 amount, address indexed beneficiary);
    event FundsTransferred(address indexed from, address indexed to, uint256 amount);
    event RootSet(bytes32 root, string proofHash);

    // An optional function invoked before each test case is run
    function setUp() public virtual {
        // initialize accounts
        owner = createUser();
        wallet = createUser();
        addr1 = createUser();
        addr2 = createUser();
        addr3 = createUser();
        accounts = createUsers(5);

        // initialize contracts
        usdt = new TestUSDT();
        vm.startPrank(owner);
        token = new Token(address(usdt), wallet);
        vm.stopPrank();

        // mint 1000 usdt for addr1 and addr2
        usdt.mint(addr1, this.toWei(2000, USDT_DECIMALS));
        usdt.mint(addr2, this.toWei(2000, USDT_DECIMALS));
    }

    function tokenPrice(uint256 amount) public pure returns (uint256) {
        return toWei(200, USDT_DECIMALS) * amount;
    }

    uint256 internal randNonce = 0;

    function randMod(uint256 _modulus) internal returns (uint256) {
        // increase nonce
        randNonce++;
        return
            (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) %
                _modulus) + 2;
    }
}

contract ConstructorTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function testName() public {
        assertEq(token.name(), "Token NFT");
    }

    function testSymbol() public {
        assertEq(token.symbol(), "TNFT");
    }

    function testMaxSupply() public {
        assertEq(token.maxSupply(), 300);
    }

    function testPrice() public {
        assertEq(token.price(), toWei(200, USDT_DECIMALS));
    }

    function testWallet() public {
        assertEq(token.wallet(), wallet);
    }

    function testOwner() public {
        assertEq(token.owner(), owner);
    }

    function testTotalSupply() public {
        assertEq(token.totalSupply(), 0);
    }

    function testUsdt() public {
        assertEq(address(token.usdt()), address(usdt));
    }

    function testUri() public {
        assertEq(token.uri(1), "ipfs://QmQFkLSQysj94s5GvTHPyzTxrawwtjgiiYS2TBLgrvw8CW/6338");
    }
}

contract MintTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function testMint10Nfts() public {
        uint32 nftsToMint = 10;
        uint256 price = tokenPrice(nftsToMint);

        // aprove usdt to token
        vm.prank(addr1);
        usdt.approve(address(token), price);

        assertEq(usdt.balanceOf(wallet), 0);

        // mint 10 nfts
        vm.prank(addr1); // addr1 as msg.sender for next call
        vm.expectEmit(true, true, true, true); // expect NFTMinted and FundsTransferred to be fired
        emit NFTMinted(1, nftsToMint, addr1);
        emit FundsTransferred(addr1, wallet, toWei(2000, USDT_DECIMALS));
        token.mint(price, nftsToMint);

        assertEq(usdt.balanceOf(wallet), price);
        assertEq(token.balanceOf(addr1, 1), nftsToMint);
        assertEq(token.totalSupply(), nftsToMint);
    }

    function testExpectRevertIfMintMoreThan11PerTxn() public {
        uint32 nftsToMint = 11;
        uint256 price = tokenPrice(nftsToMint);

        // aprove usdt to token
        usdt.mint(addr1, toWei(3000, USDT_DECIMALS));
        vm.prank(addr1);
        usdt.approve(address(token), price);

        vm.expectRevert(abi.encodeWithSignature("MaxTenMintsPerTxn()"));
        vm.prank(addr1);
        token.mint(price, nftsToMint);
    }

    function testExpectRevertIfUsdtNotApproved() public {
        uint32 nftsToMint = 1;
        uint256 price = tokenPrice(nftsToMint);

        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        vm.prank(addr1);
        token.mint(price, nftsToMint);
    }
}

contract FreeMintTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function testMint2NftsForAccounts0ByOwner() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true); // expect NFTMinted and FundsTransferred to be fired
        emit NFTMinted(1, 2, accounts[0]);
        token.freeMint(accounts[0], 2);

        assertEq(token.balanceOf(accounts[0], 1), 2);
        assertEq(token.totalSupply(), 2);
    }

    function testExpectRevertFreeMintIfCalledByNonOwner() public {
        vm.prank(addr1);
        vm.expectRevert("Ownable: caller is not the owner");
        token.freeMint(accounts[0], 1);
    }
}

contract SetRootTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function testExpectRevertSetRootIfCalledByNonOwner() public {
        bytes32 _root = 0xdefa96435aec82d201dbd2e5f050fb4e1fef5edac90ce1e03953f916a5e1132d;
        vm.prank(addr1);
        vm.expectRevert("Ownable: caller is not the owner");
        token.setRoot(_root, "_proofHash");
    }
}

contract ClaimTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    struct FuzzArgs {
        address[10] identifiers;
        uint256[10] amounts;
        uint256 index;
    }

    struct Identifier {
        uint256 index;
        address account;
        uint256 amount;
    }

    function testClaimWithValidInput() public {
        Merkle merkle = new Merkle();

        // create a new array to store identifier's index, account, amount
        Identifier[] memory identifiers = new Identifier[](accounts.length);

        // create a new array to store bytes32 hashes of identifiers
        bytes32[] memory hashedIdentifiers = new bytes32[](accounts.length);

        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 _index = i;
            address _account = accounts[i];
            uint256 _amount = i + 1;

            Identifier memory identifier = Identifier({
                index: _index,
                account: _account,
                amount: _amount
            });
            identifiers[i] = identifier;

            // hash identifier and store to generate proof
            hashedIdentifiers[i] = keccak256(abi.encodePacked(_index, _account, _amount));
            emit log_named_uint("index", _index);
            emit log_named_address("account", _account);
            emit log_named_uint("amount", _amount);
        }

        // Get Root, Proof, and Verify
        bytes32 root = merkle.getRoot(hashedIdentifiers);

        uint256 index = identifiers[2].index;
        address caller = identifiers[2].account;
        uint256 amount = identifiers[2].amount;

        // will get proof for accounts[2] value
        bytes32[] memory proof = merkle.getProof(hashedIdentifiers, index);
        bytes32 leaf = keccak256(abi.encodePacked(index, caller, amount));
        // emit log_bytes32(hashedIdentifiers[index]);

        bool verified = merkle.verifyProof(root, proof, hashedIdentifiers[index]); // true!
        assertTrue(verified);

        // set root
        vm.prank(owner);
        vm.expectEmit(true, true, true, true); // expect RootSet to be fired
        emit RootSet(root, "ipfsHash");
        token.setRoot(root, "ipfsHash");
        assertTrue(token.verify(proof, leaf));
        assertEq(token.root(), root);
        assertEq(token.proofHash(), "ipfsHash");

        // claim
        vm.prank(caller);
        vm.expectEmit(true, true, true, true); // expect NFTMinted to be fired
        emit NFTMinted(1, uint32(amount), caller);
        token.claim(index, amount, proof);

        assertEq(token.balanceOf(caller, 1), amount);
        assertEq(token.totalSupply(), amount);

        // fail if wrong index given
        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSignature("InvalidProof()"));
        token.claim(100, amount, proof);

        // fail if wrong amount given
        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSignature("InvalidProof()"));
        token.claim(index, 23, proof);

        // fail if wrong proof given
        vm.prank(caller);
        vm.expectRevert(abi.encodeWithSignature("InvalidProof()"));

        bytes32[] memory invalidProof = new bytes32[](2);
        invalidProof[0] = 0x838d10ace3a0ee1ad25535eae94ac4a7730141a1051a5fc2c97b402a84be1af8;
        invalidProof[1] = 0x740fda1488c3f2289214c3444557361eb7c67ccca0968d40be6dc77936743bfb;

        token.claim(index, amount, invalidProof);
    }

    function testRandomAmountsAndExpectRevertIfClaimTwice() public {
        uint256 totalAmount = 0;
        Merkle merkle = new Merkle();

        // create a new array to store identifier's index, account, amount
        Identifier[] memory identifiers = new Identifier[](accounts.length);

        // create a new array to store bytes32 hashes of identifiers
        bytes32[] memory hashedIdentifiers = new bytes32[](accounts.length);

        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 _index = i;
            address _account = accounts[i];
            uint256 _amount = randMod(i + 1 + block.timestamp);

            Identifier memory identifier = Identifier({
                index: _index,
                account: _account,
                amount: _amount
            });
            identifiers[i] = identifier;

            // hash identifier and store to generate proof
            hashedIdentifiers[i] = keccak256(abi.encodePacked(_index, _account, _amount));
            emit log_named_uint("index", _index);
            emit log_named_address("account", _account);
            emit log_named_uint("amount", _amount);
        }

        // Get Root, Proof, and Verify
        bytes32 root = merkle.getRoot(hashedIdentifiers);

        // set root
        vm.prank(owner);
        vm.expectEmit(true, true, true, true); // expect RootSet to be fired
        emit RootSet(root, "ipfsHash");
        token.setRoot(root, "ipfsHash");

        assertEq(token.root(), root);
        assertEq(token.proofHash(), "ipfsHash");

        for (uint256 i = 0; i < identifiers.length; i++) {
            uint256 _index = identifiers[i].index;
            address _account = identifiers[i].account;
            uint256 _amount = identifiers[i].amount;

            bytes32[] memory _proof = merkle.getProof(hashedIdentifiers, _index);

            // claim
            vm.prank(_account);
            vm.expectEmit(true, true, true, true); // expect NFTMinted to be fired
            emit NFTMinted(1, uint32(_amount), _account);
            token.claim(_index, _amount, _proof);

            assertEq(token.balanceOf(_account, 1), _amount);

            totalAmount += _amount;
        }
        assertEq(token.totalSupply(), totalAmount);

        uint256 index = identifiers[2].index;
        address account = identifiers[2].account;
        uint256 amount = identifiers[2].amount;
        bytes32[] memory proof = merkle.getProof(hashedIdentifiers, index);

        vm.prank(account);
        vm.expectRevert(abi.encodeWithSignature("AlreadyClaimed()"));
        token.claim(index, amount, proof);
    }

    function testClaimWithValidInputWithFuzzing(FuzzArgs memory args) public {
        vm.assume(args.index < args.identifiers.length);
        uint256 amountsLength = args.amounts.length;
        uint256 identifiersLength = args.identifiers.length;

        assertTrue(amountsLength == identifiersLength, "amounts and identifiers not equal");

        for (uint256 i = 0; i < amountsLength; i++) {
            vm.assume(args.amounts[i] > 0);
            assertTrue(args.amounts[i] != 0, "amounts zero");
        }

        for (uint256 i = 0; i < identifiersLength; i++) {
            vm.assume(args.identifiers[i] != address(0));
            assertTrue(args.identifiers[i] != address(0), "identifiers zero");

            vm.deal(args.identifiers[i], 100 ether);
        }

        Merkle merkle = new Merkle();

        // create a new array to store identifier's index, account, amount
        Identifier[] memory identifiers = new Identifier[](identifiersLength);

        // create a new array to store bytes32 hashes of identifiers
        bytes32[] memory hashedIdentifiers = new bytes32[](identifiersLength);

        for (uint256 i = 0; i < identifiersLength; i++) {
            uint256 _index = i;
            address _account = args.identifiers[i];
            uint256 _amount = args.amounts[i];

            Identifier memory identifier = Identifier({
                index: _index,
                account: _account,
                amount: _amount
            });
            identifiers[i] = identifier;

            // hash identifier and store to generate proof
            hashedIdentifiers[i] = keccak256(abi.encodePacked(_index, _account, _amount));
            emit log_named_uint("index", _index);
            emit log_named_address("account", _account);
            emit log_named_uint("amount", _amount);
        }

        // Get Root, Proof, and Verify
        bytes32 root = merkle.getRoot(hashedIdentifiers);

        uint256 index = identifiers[args.index].index;
        address caller = identifiers[args.index].account;
        uint256 amount = identifiers[args.index].amount;

        // will get proof for accounts[2] value
        bytes32[] memory proof = merkle.getProof(hashedIdentifiers, index);
        bytes32 leaf = keccak256(abi.encodePacked(index, caller, amount));

        bool verified = merkle.verifyProof(root, proof, hashedIdentifiers[index]); // true!
        assertTrue(verified);

        // set root
        vm.prank(owner);
        vm.expectEmit(true, true, true, true); // expect RootSet to be fired
        emit RootSet(root, "ipfsHash");
        token.setRoot(root, "ipfsHash");
        assertTrue(token.verify(proof, leaf));
        assertEq(token.root(), root);
        assertEq(token.proofHash(), "ipfsHash");

        // // claim
        // vm.prank(caller);
        // vm.expectEmit(true, true, true, true); // expect NFTMinted to be fired
        // emit NFTMinted(1, uint32(amount), caller);
        // token.claim(index, amount, proof);

        // assertEq(token.balanceOf(caller, 1), amount);
        // assertEq(token.totalSupply(), amount);

        // // fail if wrong index given
        // vm.prank(caller);
        // vm.expectRevert(abi.encodeWithSignature("InvalidProof()"));
        // token.claim(100, amount, proof);

        // // fail if wrong amount given
        // vm.prank(caller);
        // vm.expectRevert(abi.encodeWithSignature("InvalidProof()"));
        // token.claim(index, 23, proof);

        // // fail if wrong proof given
        // vm.prank(caller);
        // vm.expectRevert(abi.encodeWithSignature("InvalidProof()"));

        // bytes32[] memory invalidProof = new bytes32[](2);
        // invalidProof[0] = 0x838d10ace3a0ee1ad25535eae94ac4a7730141a1051a5fc2c97b402a84be1af8;
        // invalidProof[1] = 0x740fda1488c3f2289214c3444557361eb7c67ccca0968d40be6dc77936743bfb;

        // token.claim(index, amount, invalidProof);
    }
}
