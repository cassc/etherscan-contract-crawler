// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {LibMint} from "./LibMint.sol";

library LibMerkleProof {
    function verifyClaim(bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return
            _verify(proof, LibMint.mintStorage().claimingMerkleRoot);
    }

    function verifyPrivateSale(bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return
            _verify(proof, LibMint.mintStorage().privateSaleMerkleRoot);
    }

    function _verify(bytes32[] memory proof, bytes32 merkleRoot) private view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }
}