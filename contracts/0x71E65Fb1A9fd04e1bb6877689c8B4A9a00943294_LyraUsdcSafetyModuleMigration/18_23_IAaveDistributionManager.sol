// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {DistributionTypes} from '../lib/DistributionTypes.sol';

interface IAaveDistributionManager {
  function configureAssets(DistributionTypes.AssetConfigInput[] calldata assetsConfigInput)
    external;
}