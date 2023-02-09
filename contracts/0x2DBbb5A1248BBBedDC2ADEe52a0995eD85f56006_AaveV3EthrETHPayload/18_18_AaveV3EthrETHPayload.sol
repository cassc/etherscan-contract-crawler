// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {IGenericV3ListingEngine, AaveV3ListingEthereum} from 'aave-helpers/v3-listing-engine/AaveV3ListingEthereum.sol';

/**
 * @title This proposal lists rETH on Aave V3 Ethereum
 * @author BGD Labs
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0xb06bac2b74fb2fafcfb21492c938f03a52a389d545b9975f8dc926374e966b04
 * - Dicussion: https://governance.aave.com/t/arc-onboard-reth-rocket-pool-eth-to-aave-v3-ethereum-market/11371/14
 */
contract AaveV3EthrETHPayload is AaveV3ListingEthereum {
  address constant RETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;
  address constant RETH_USD_FEED = 0x05225Cd708bCa9253789C1374e4337a019e99D56;

  constructor() AaveV3ListingEthereum(IGenericV3ListingEngine(AaveV3Ethereum.LISTING_ENGINE)) {}

  function getAllConfigs() public pure override returns (IGenericV3ListingEngine.Listing[] memory) {
    IGenericV3ListingEngine.Listing[] memory listings = new IGenericV3ListingEngine.Listing[](1);

    listings[0] = IGenericV3ListingEngine.Listing({
      asset: RETH,
      assetSymbol: 'rETH',
      priceFeed: RETH_USD_FEED,
      rateStrategy: 0x24701A6368Ff6D2874d6b8cDadd461552B8A5283,
      enabledToBorrow: true,
      stableRateModeEnabled: false,
      borrowableInIsolation: false,
      withSiloedBorrowing: false,
      flashloanable: true,
      ltv: 67_00,
      liqThreshold: 74_00,
      liqBonus: 7_50,
      reserveFactor: 15_00,
      supplyCap: 10_000,
      borrowCap: 1_200,
      debtCeiling: 0,
      liqProtocolFee: 10_00,
      eModeCategory: 0
    });

    return listings;
  }
}