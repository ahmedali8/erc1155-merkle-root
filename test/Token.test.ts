import { keccak256 } from "@ethersproject/solidity";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";

import { MerkleDistributorInfo, parseBalanceMap } from "../scripts/merkleroot/parse-balance-map";
import { TestUSDT, TestUSDT__factory, Token, Token__factory } from "../src/types";
import { randomInteger, toBN, toWei } from "../utils/format";
import { Errors } from "./Errors";

const DEBUG = true;

describe("Token Unit tests", () => {
  let contract: Token;
  let usdt: TestUSDT;

  let owner: SignerWithAddress;
  let wallet: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addr3: SignerWithAddress;
  let accounts: SignerWithAddress[];

  const usdtDecimals = 6;

  const tokensPrice = (amount: number) => {
    const priceForOne = toWei("200", usdtDecimals);
    const price = priceForOne.mul(amount);
    if (price !== undefined) return price;
    return priceForOne;
  };

  beforeEach(async () => {
    [owner, wallet, addr1, addr2, addr3, ...accounts] = await ethers.getSigners();

    const TestUSDTContract: TestUSDT__factory = await ethers.getContractFactory("TestUSDT");
    usdt = await (await TestUSDTContract.deploy()).deployed();

    const TokenContract: Token__factory = await ethers.getContractFactory("Token");
    contract = await (await TokenContract.deploy(usdt.address, wallet.address)).deployed();

    // mint 1000 usdt for addr1 and addr2
    await usdt.mint(addr1.address, toWei("2000", usdtDecimals));
    await usdt.mint(addr2.address, toWei("2000", usdtDecimals));
  });

  describe("#constructor", () => {
    it("#name", async () => {
      expect(await contract.name()).to.equal("Token NFT");
    });
    it("#symbol", async () => {
      expect(await contract.symbol()).to.equal("TNFT");
    });
    it("#maxSupply", async () => {
      expect(await contract.maxSupply()).to.equal(300);
    });
    it("#price", async () => {
      expect(await contract.price()).to.equal(toWei("200", usdtDecimals));
    });
    it("#wallet", async () => {
      expect(await contract.wallet()).to.equal(wallet.address);
    });
    it("#owner", async () => {
      expect(await contract.owner()).to.equal(owner.address);
    });
    it("#totalSupply", async () => {
      expect(await contract.totalSupply()).to.equal(0);
    });
    it("#usdt", async () => {
      expect(await contract.usdt()).to.equal(usdt.address);
    });
    it("#uri", async () => {
      expect(await contract.uri(1)).to.equal(
        "ipfs://QmQFkLSQysj94s5GvTHPyzTxrawwtjgiiYS2TBLgrvw8CW/6338"
      );
    });
  });

  describe("#mint", () => {
    it("should mint 10 nfts", async () => {
      const price = tokensPrice(10);

      // approve usdt to contract
      await usdt.connect(addr1).approve(contract.address, price);
      expect(await usdt.balanceOf(wallet.address)).to.equal(0);

      // mint 10 nfts
      await expect(contract.connect(addr1).mint(price, 10))
        .to.emit(contract, "NFTMinted")
        .to.emit(contract, "FundsTransferred")
        .withArgs(addr1.address, wallet.address, price);
      expect(await usdt.balanceOf(wallet.address)).to.equal(price);

      expect(await contract.balanceOf(addr1.address, 1)).to.equal(10);
      expect(await contract.totalSupply()).to.equal(10);
    });

    it("should fail to mint more than 11 per txn", async () => {
      const price = tokensPrice(11);
      // approve usdt to contract
      await usdt.mint(addr1.address, toWei("3000", usdtDecimals));
      await usdt.connect(addr1).approve(contract.address, price);

      await expect(contract.connect(addr1).mint(price, 11)).to.be.revertedWith(
        Errors.MaxTenMintsPerTxn
      );
    });

    it("should fail if usdt not approved", async () => {
      const price = tokensPrice(1);
      await expect(contract.connect(addr1).mint(price, 1)).to.be.revertedWith(
        "ERC20: transfer amount exceeds allowance"
      );
    });
  });

  describe("#claim", () => {
    it("should be claimable with valid (index,amount,proof) only", async () => {
      const caller = accounts[2];
      const list: {
        address: string;
        amount: number;
      }[] = accounts.map((account, i) => ({
        address: account.address,
        amount: 1,
      }));

      const treeData: MerkleDistributorInfo = parseBalanceMap(list);

      const root = treeData.merkleRoot;
      const index = treeData.claims[caller.address].index;
      const amount = parseInt(treeData.claims[caller.address].amount);
      const proof = treeData.claims[caller.address].proof;

      const leaf = keccak256(["uint256", "address", "uint256"], [index, caller.address, amount]);

      // set root
      await contract.connect(owner).setRoot(root, "ipfsHash");
      expect(await contract.verify(proof, leaf)).to.equal(true);
      expect(await contract.root()).to.equal(root);
      expect(await contract.proofHash()).to.equal("ipfsHash");

      // claim
      await expect(contract.connect(caller).claim(index, amount, proof)).to.emit(
        contract,
        "NFTMinted"
      );
      expect(await contract.balanceOf(caller.address, 1)).to.equal(1);
      expect(await contract.totalSupply()).to.equal(1);

      // fail if wrong index given
      await expect(contract.connect(caller).claim(100, amount, proof)).to.be.revertedWith(
        Errors.InvalidProof
      );

      // fail if wrong amount given
      await expect(contract.connect(caller).claim(index, 23, proof)).to.be.revertedWith(
        Errors.InvalidProof
      );

      // fail if wrong proof given
      const invalidProof = [
        "0x838d10ace3a0ee1ad25535eae94ac4a7730141a1051a5fc2c97b402a84be1af8",
        "0x740fda1488c3f2289214c3444557361eb7c67ccca0968d40be6dc77936743bfb",
      ];
      await expect(contract.connect(caller).claim(index, amount, invalidProof)).to.be.revertedWith(
        Errors.InvalidProof
      );
    });

    it("should able to claim with different amounts but fail if try to claim twice", async () => {
      let totalAmount: number = 0;
      const list: {
        address: string;
        amount: number;
      }[] = [];
      for (let i = 0; i < 5; i++) {
        const randNum = randomInteger(1, 10);
        list.push({ address: accounts[i].address, amount: randNum });
      }

      const treeData: MerkleDistributorInfo = parseBalanceMap(list);

      const root = treeData.merkleRoot;

      // set root
      await contract.connect(owner).setRoot(root, "ipfsHash");
      expect(await contract.root()).to.equal(root);
      expect(await contract.proofHash()).to.equal("ipfsHash");

      for (let i = 0; i < list.length; i++) {
        const { address, amount } = list[i];
        if (DEBUG) console.log(`i: ${i}, address: ${address}, amount: ${amount}`);

        const signer = await ethers.getSigner(address);
        const index = treeData.claims[signer.address].index;
        const amountFromTree = treeData.claims[signer.address].amount;
        const proof = treeData.claims[signer.address].proof;

        expect(amountFromTree).to.equal(amount.toString());

        // claim
        await expect(contract.connect(signer).claim(index, amount, proof)).to.emit(
          contract,
          "NFTMinted"
        );
        expect(await contract.balanceOf(signer.address, 1)).to.equal(amount);

        totalAmount = totalAmount + amount;
      }

      expect(await contract.totalSupply()).to.equal(totalAmount);

      await expect(
        contract
          .connect(accounts[3])
          .claim(
            treeData.claims[accounts[3].address].index,
            treeData.claims[accounts[3].address].amount,
            treeData.claims[accounts[3].address].proof
          )
      ).to.be.revertedWith(Errors.AlreadyClaimed);
    });
  });

  describe("#freeMint", () => {
    it("mints 2 tokens for accounts[0] by owner", async () => {
      await expect(contract.connect(owner).freeMint(accounts[0].address, 2)).to.emit(
        contract,
        "NFTMinted"
      );

      expect(await contract.balanceOf(accounts[0].address, 1)).to.equal(2);
      expect(await contract.totalSupply()).to.equal(2);
    });

    it("fails other than owner", async () => {
      await expect(contract.connect(addr1).freeMint(accounts[0].address, 1)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
  });

  describe("#setRoot", () => {
    it("fails to set root by non-owner", async () => {
      const invalidRoot = "0xdefa96435aec82d201dbd2e5f050fb4e1fef5edac90ce1e03953f916a5e1132d";

      await expect(contract.connect(addr1).setRoot(invalidRoot, "ipfsHash")).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
  });
});
