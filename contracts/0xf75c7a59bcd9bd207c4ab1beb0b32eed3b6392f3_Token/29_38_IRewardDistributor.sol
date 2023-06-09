// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "../IRewards.sol";

interface IRewardDistributor {

    event DistributionConfigUpdate(
        IRewards.DistributionConfig prevValue,
        IRewards.DistributionConfig newValue,
        address indexed sender
    );

    function MANAGE_DISTRIBUTION_CONFIG_ROLE() external view returns (bytes32);

    function distributionConfig() external view returns (IRewards.DistributionConfig memory);
    function updateDistributionConfig(IRewards.DistributionConfig memory newConfig) external;
}