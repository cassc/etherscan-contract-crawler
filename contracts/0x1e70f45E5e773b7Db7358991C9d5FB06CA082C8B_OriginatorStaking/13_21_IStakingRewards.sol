// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import '../lib/DistributionTypes.sol';

interface IStakingRewards {
    function changeDistributionEndDate(uint256 date) external;
    function configureAssets(DistributionTypes.AssetConfigInput[] memory assetsConfigInput)
        external;
}