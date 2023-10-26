// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3PayloadEthereum, IEngine, Rates, EngineFlags} from 'lib/aave-helpers/src/v3-config-engine/AaveV3PayloadEthereum.sol';

/**
 * @title STG onboarding on AaveV3 Ethereum Market
 * @author Alice Rozengarden (@Rozengarden - Aave-chan initiative)
 * - Snapshot: https://signal.aave.com/#/proposal/0x917d0a2c0d9a107d5f8c83b76c291bb34a6a94b85b833b2add96bce7681522ef
 * - Discussion: https://governance.aave.com/t/arfc-stg-onboarding-on-aavev3-ethereum-market/14973
 */
contract AaveV3_Ethereum_STGOnboardingOnAaveV3EthereumMarket_20231008 is AaveV3PayloadEthereum {
  address public constant STG = 0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6;
  address public constant STG_PRICE_FEED = 0x7A9f34a0Aa917D438e9b6E630067062B7F8f6f3d;

  function newListings() public pure override returns (IEngine.Listing[] memory) {
    IEngine.Listing[] memory listings = new IEngine.Listing[](1);

    listings[0] = IEngine.Listing({
      asset: STG,
      assetSymbol: 'STG',
      priceFeed: STG_PRICE_FEED,
      rateStrategyParams: Rates.RateStrategyParams({
        optimalUsageRatio: _bpsToRay(45_00),
        baseVariableBorrowRate: 0,
        variableRateSlope1: _bpsToRay(7_00),
        variableRateSlope2: _bpsToRay(300_00),
        stableRateSlope1: _bpsToRay(13_00),
        stableRateSlope2: _bpsToRay(300_00),
        baseStableRateOffset: _bpsToRay(3_00),
        stableRateExcessOffset: _bpsToRay(5_00),
        optimalStableToTotalDebtRatio: _bpsToRay(20_00)
      }),
      enabledToBorrow: EngineFlags.ENABLED,
      stableRateModeEnabled: EngineFlags.DISABLED,
      borrowableInIsolation: EngineFlags.DISABLED,
      withSiloedBorrowing: EngineFlags.DISABLED,
      flashloanable: EngineFlags.ENABLED,
      ltv: 35_00,
      liqThreshold: 40_00,
      liqBonus: 10_00,
      reserveFactor: 20_00,
      supplyCap: 10_000_000,
      borrowCap: 5_500_000,
      debtCeiling: 3_000_000,
      liqProtocolFee: 10_00,
      eModeCategory: 0
    });

    return listings;
  }
}