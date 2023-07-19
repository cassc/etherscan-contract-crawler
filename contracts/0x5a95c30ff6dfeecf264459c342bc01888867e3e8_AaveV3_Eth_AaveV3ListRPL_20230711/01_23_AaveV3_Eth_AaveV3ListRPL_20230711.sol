// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3PayloadEthereum, IEngine, Rates, EngineFlags} from 'aave-helpers/v3-config-engine/AaveV3PayloadEthereum.sol';

/**
 * @title Add RPL to Aave V3 pool
 * @author Marc Zeller (@marczeller - Aave Chan Initiative)
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0x036f9ce8b4a9fef0156ccf6b2a205d56d4f23b7ab9a485a16d7c8173cd85a316
 * - Discussion: https://governance.aave.com/t/arfc-add-rpl-to-ethereum-v3/13181
 */
contract AaveV3_Eth_AaveV3ListRPL_20230711 is AaveV3PayloadEthereum {
  address public constant RPL_USD_FEED = 0x4E155eD98aFE9034b7A5962f6C84c86d869daA9d;
  address public constant RPL = 0xD33526068D116cE69F19A9ee46F0bd304F21A51f;

  function newListings() public pure override returns (IEngine.Listing[] memory) {
    IEngine.Listing[] memory listings = new IEngine.Listing[](1);

    listings[0] = IEngine.Listing({
      asset: RPL,
      assetSymbol: 'RPL',
      priceFeed: RPL_USD_FEED,
      rateStrategyParams: Rates.RateStrategyParams({
        optimalUsageRatio: _bpsToRay(80_00),
        baseVariableBorrowRate: 0,
        variableRateSlope1: _bpsToRay(8_50),
        variableRateSlope2: _bpsToRay(87_00),
        stableRateSlope1: _bpsToRay(8_50),
        stableRateSlope2: _bpsToRay(87_00),
        baseStableRateOffset: _bpsToRay(1_00),
        stableRateExcessOffset: _bpsToRay(8_00),
        optimalStableToTotalDebtRatio: _bpsToRay(20_00)
      }),
      enabledToBorrow: EngineFlags.ENABLED,
      stableRateModeEnabled: EngineFlags.DISABLED,
      borrowableInIsolation: EngineFlags.DISABLED,
      withSiloedBorrowing: EngineFlags.DISABLED,
      flashloanable: EngineFlags.ENABLED,
      ltv: 0,
      liqThreshold: 0,
      liqBonus: 0,
      reserveFactor: 20_00,
      supplyCap: 105_000,
      borrowCap: 105_000,
      debtCeiling: 0,
      liqProtocolFee: 0,
      eModeCategory: 0
    });

    return listings;
  }
}