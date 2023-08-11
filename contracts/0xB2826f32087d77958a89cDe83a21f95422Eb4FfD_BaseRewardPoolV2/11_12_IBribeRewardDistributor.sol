// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBribeRewardDistributor {
    struct Claimable {
        address token;
        uint256 amount;
    }

    struct Claim {
        address token;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
    }

    function getClaimable(Claim[] calldata _claims) external view returns(Claimable[] memory);

    function claim(Claim[] calldata _claims) external;
}