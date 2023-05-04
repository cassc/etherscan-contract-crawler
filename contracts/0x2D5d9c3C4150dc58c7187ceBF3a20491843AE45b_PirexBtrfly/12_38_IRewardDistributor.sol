// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRewardDistributor {
    struct Distribution {
        address token;
        bytes32 merkleRoot;
        bytes32 proof;
    }

    struct Claim {
        address token;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
    }

    function claim(Claim[] calldata claims) external;

    function updateRewardsMetadata(Distribution[] calldata distributions)
        external;

    function claimed(address token, address account)
        external
        view
        returns (uint256 amount);
}