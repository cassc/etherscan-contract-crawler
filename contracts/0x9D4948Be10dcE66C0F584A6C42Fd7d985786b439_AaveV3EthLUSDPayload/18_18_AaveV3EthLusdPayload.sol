// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {IGenericV3ListingEngine, AaveV3ListingEthereum} from 'aave-helpers/v3-listing-engine/AaveV3ListingEthereum.sol';

/**
 * @title This proposal lists LUSD on Aave V3 Ethereum
 * @author @marczeller - Aave-Chan Initiative
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0xda3519f11e2308239d5f179b2579fe921b2a421eb752aba959779ee9ecea0d69
 * - Discussion: https://governance.aave.com/t/arc-add-lusd-to-ethereum-v3-market/11522
 */
contract AaveV3EthLUSDPayload is AaveV3ListingEthereum {
  address constant LUSD = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
  address constant LUSD_USD_FEED = 0x3D7aE7E594f2f2091Ad8798313450130d0Aba3a0;

  constructor() AaveV3ListingEthereum(IGenericV3ListingEngine(AaveV3Ethereum.LISTING_ENGINE)) {}

  function getAllConfigs() public pure override returns (IGenericV3ListingEngine.Listing[] memory) {
    IGenericV3ListingEngine.Listing[] memory listings = new IGenericV3ListingEngine.Listing[](1);

    listings[0] = IGenericV3ListingEngine.Listing({
      asset: LUSD,
      assetSymbol: 'LUSD',
      priceFeed: LUSD_USD_FEED,
      rateStrategy: 0x349684Da30f8c9Affeaf21AfAB3a1Ad51f5d95A3,
      enabledToBorrow: true,
      stableRateModeEnabled: false,
      borrowableInIsolation: false,
      withSiloedBorrowing: false,
      flashloanable: true,
      ltv: 0,
      liqThreshold: 0,
      liqBonus: 0,
      reserveFactor: 10_00,
      supplyCap: 3_000_000,
      borrowCap: 1_210_000,
      debtCeiling: 0,
      liqProtocolFee: 10_00,
      eModeCategory: 0
    });

    return listings;
  }
}