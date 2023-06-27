// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface ITreeWithClaimOnBehalf {
    function claimOnBehalf(
        address user,
        uint8[] calldata treeIds,
        uint256[] calldata amounts,
        bytes32[][] calldata merkleProofs
    ) external;
}

contract ClaimFromTreesHelper {
    constructor() {}

    function claimFromMultipleTrees(
        ITreeWithClaimOnBehalf[] calldata trees,
        uint8[][] calldata treeIds,
        uint256[][] calldata amounts,
        bytes32[][][] calldata merkleProofs
    ) external {
        for (uint i; i < trees.length; i++) {
            trees[i].claimOnBehalf(msg.sender, treeIds[i], amounts[i], merkleProofs[i]);
        }
    }
}