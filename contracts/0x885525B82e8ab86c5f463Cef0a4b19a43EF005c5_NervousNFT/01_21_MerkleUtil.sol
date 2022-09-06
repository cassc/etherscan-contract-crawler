// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

library MerkleUtil {
    function verifyAddressProof(
        address addr,
        bytes32 root,
        bytes32[] calldata proof
    ) internal pure returns (bool) {
        return
            MerkleProof.verify(proof, root, keccak256(abi.encodePacked(addr)));
    }
}