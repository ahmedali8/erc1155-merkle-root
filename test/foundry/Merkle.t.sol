// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Utils } from "./utils/Utils.sol";
import { Merkle } from "murky/Merkle.sol";

contract MerkleTest is Utils {
    function testDummyMerkleTree() public {
        Merkle merkle = new Merkle();

        // Toy Data
        bytes32[] memory data = new bytes32[](4);
        data[0] = bytes32("0x0");
        data[1] = bytes32("0x1");
        data[2] = bytes32("0x2");
        data[3] = bytes32("0x3");

        // Get Root, Proof, and Verify
        bytes32 root = merkle.getRoot(data);
        bytes32[] memory proof = merkle.getProof(data, 2); // will get proof for 0x2 value
        bool verified = merkle.verifyProof(root, proof, data[2]); // true!
        assertTrue(verified);

        // test same tree with openzeppelin
        bool ozVerified = MerkleProof.verify(proof, root, data[2]);
        assertTrue(ozVerified);
    }
}
