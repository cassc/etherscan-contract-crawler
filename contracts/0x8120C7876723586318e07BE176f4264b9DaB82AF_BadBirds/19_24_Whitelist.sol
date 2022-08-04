//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

library Whitelist {
    struct Data {
        bytes32 merkleTreeRoot;
        mapping(address => bool) accounts;
    }

    function isWhitelisted(
        Data storage data_,
        address account_,
        bytes32[] calldata proof_
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account_));
        return            
            MerkleProof.verify(proof_, data_.merkleTreeRoot, leaf) || data_.accounts[account_];
    }
}