// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IMerkleProofVerify {
    /**
     * @dev Emitted when root is set.
     */
    event RootSet(bytes32 root, string proofHash);

    /**
     * @dev Returns the root.
     */
    function root() external view returns (bytes32);

    /**
     * @dev Returns the proofHash.
     * ipfs hash containing the json file of leaf proofs.
     */
    function proofHash() external view returns (string memory);

    /**
     * @dev Returns boolean value for `_proof` and `_leaf`.
     */
    function verify(bytes32[] memory _proof, bytes32 _leaf) external view returns (bool);

    /**
     * @dev Returns bytes32 hash for `_proof` and `_leaf`.
     */
    function processProof(bytes32[] memory _proof, bytes32 _leaf) external pure returns (bytes32);
}
