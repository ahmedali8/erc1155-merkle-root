// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IMerkleProofVerify.sol";

contract MerkleProofVerify is IMerkleProofVerify {
    /**
     * @dev See {IMerkleProofVerify-root}
     */
    bytes32 public override root;

    /**
     * @dev See {IMerkleProofVerify-proofHash}
     */
    string public override proofHash;

    /// @dev Error thrown when root is invalid.
    error InvalidRoot();

    /**
     * @dev See {IMerkleProofVerify-verify}
     */
    function verify(bytes32[] memory _proof, bytes32 _leaf)
        public
        view
        virtual
        override
        returns (bool)
    {
        return MerkleProof.verify(_proof, root, _leaf);
    }

    /**
     * @dev See {IMerkleProofVerify-processProof}
     */
    function processProof(bytes32[] memory _proof, bytes32 _leaf)
        public
        pure
        virtual
        override
        returns (bytes32)
    {
        return MerkleProof.processProof(_proof, _leaf);
    }

    /**
     * @dev Sets `root` and `proofHash`.
     *
     * Emits a {RootSet} event indicating update of merkle root hash.
     *
     * @param _root - markle root
     * @param _proofHash - ipfs hash containing json file of proofs.
     *
     * Requirements:
     *
     * - `_root` and `_proofHash` must be valid.
     */
    function _setRoot(bytes32 _root, string memory _proofHash) internal virtual {
        if (_root == "" && bytes(_proofHash).length == 0) revert InvalidRoot();
        root = _root;
        proofHash = _proofHash;
        emit RootSet(_root, _proofHash);
    }
}
