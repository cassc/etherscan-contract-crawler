// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKEY3MerkleValidator {
    function validate(address addr_, bytes32[] calldata merkleProofs_)
        external
        view
        returns (bool);
}