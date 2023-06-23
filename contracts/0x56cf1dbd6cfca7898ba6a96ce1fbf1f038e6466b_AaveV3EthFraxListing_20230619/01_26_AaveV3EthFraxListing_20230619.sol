// SPDX-License-Identifier: MIT

/*
   _      ΞΞΞΞ      _
  /_;-.__ / _\  _.-;_\
     `-._`'`_/'`.-'
         `\   /`
          |  /
         /-.(
         \_._\
          \ \`;
           > |/
          / //
          |//
          \(\
           ``
     defijesus.eth
*/

pragma solidity 0.8.17;

import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveV3PayloadEthereum, IEngine, Rates, EngineFlags} from 'aave-helpers/v3-config-engine/AaveV3PayloadEthereum.sol';

/**
 * @title List FRAX on AaveV3Ethereum
 * @author defijesus - TokenLogic
 * @dev This proposal lists FRAX on Aave V3 Ethereum
 * Governance: https://governance.aave.com/t/arfc-add-frax-to-aave-v3-ethereum/13051
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xf0a3ef553905b03d36e0982719cfe25e85d97f563c3ef401f25e8455960576f8
 */
contract AaveV3EthFraxListing_20230619 is AaveV3PayloadEthereum {
  address public constant PRICE_FEED = 0xB9E1E3A9feFf48998E45Fa90847ed4D467E8BcfD;

  function newListings() public pure override returns (IEngine.Listing[] memory) {
    IEngine.Listing[] memory listings = new IEngine.Listing[](1);

    listings[0] = IEngine.Listing({
      asset: AaveV2EthereumAssets.FRAX_UNDERLYING,
      assetSymbol: 'FRAX',
      priceFeed: PRICE_FEED,
      rateStrategyParams: Rates.RateStrategyParams({
        optimalUsageRatio: _bpsToRay(80_00),
        baseVariableBorrowRate: 0,
        variableRateSlope1: _bpsToRay(4_00),
        variableRateSlope2: _bpsToRay(75_00),
        stableRateSlope1: _bpsToRay(50),
        stableRateSlope2: _bpsToRay(75_00),
        baseStableRateOffset: _bpsToRay(1_00),
        stableRateExcessOffset: _bpsToRay(8_00),
        optimalStableToTotalDebtRatio: _bpsToRay(20_00)
      }),
      enabledToBorrow: EngineFlags.ENABLED,
      stableRateModeEnabled: EngineFlags.DISABLED,
      borrowableInIsolation: EngineFlags.DISABLED,
      withSiloedBorrowing: EngineFlags.DISABLED,
      flashloanable: EngineFlags.ENABLED,
      ltv: 70_00,
      liqThreshold: 75_00,
      liqBonus: 6_00,
      reserveFactor: 10_00,
      supplyCap: 15_000_000,
      borrowCap: 12_000_000,
      debtCeiling: 10_000_000,
      liqProtocolFee: 10_00,
      eModeCategory: 0
    });

    return listings;
  }
}