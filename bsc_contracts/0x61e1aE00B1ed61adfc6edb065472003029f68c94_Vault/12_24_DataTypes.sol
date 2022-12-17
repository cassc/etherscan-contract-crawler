// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    int128 currentLiquidityRate;
    uint128 previousLiquidityIndex;
    uint128 purchaseUpperLimit;
    uint40 lastUpdateTimestamp;
    uint40 purchaseBeginTimestamp;
    uint40 purchaseEndTimestamp;
    uint40 redemptionBeginTimestamp;
    //fee rate 
    uint16 managementFeeRate;
    uint16 performanceFeeRate;
    //tokens addresses
    address oTokenAddress;
    address fundAddress;
    uint128 softUpperLimit;
  }

  struct ReserveConfigurationMap {
    //bit 0-7: Decimals
    //bit 8: Reserve is active
    //bit 9: reserve is frozen
    uint256 data;
  }
}