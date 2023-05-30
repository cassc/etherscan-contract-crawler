// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IVotiumMerkleStash {
    function claim(
        address token,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;
}