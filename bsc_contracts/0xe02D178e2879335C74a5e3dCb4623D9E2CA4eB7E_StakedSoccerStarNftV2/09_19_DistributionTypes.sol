// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

library DistributionTypes {
  struct AssetConfigInput {
    uint128 emissionPerSecond;
    uint256 totalPower;
    address underlyingAsset;
  }

  struct UserStakeInput {
    address underlyingAsset;
    uint256 tokenPower;
    uint256 totalPower;
  }
}