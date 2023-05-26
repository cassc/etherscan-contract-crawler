// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Common} from "../libraries/Common.sol";

interface IRewardDistributor {
    function updateRewardsMetadata(Common.Distribution[] calldata distributions)
        external;
}