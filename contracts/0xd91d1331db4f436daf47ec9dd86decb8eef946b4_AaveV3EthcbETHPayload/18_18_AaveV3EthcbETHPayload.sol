// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {IGenericV3ListingEngine, AaveV3ListingEthereum} from 'aave-helpers/v3-listing-engine/AaveV3ListingEthereum.sol';

/**
 * @title This proposal lists cbETH on Aave V3 Ethereum
 * @author BGD Labs
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0xcbb588f0030f7726da3d065a30c2500652bbd0def6ca5f5f17a82daca777578e
 * - Dicussion: https://governance.aave.com/t/arc-add-support-for-cbeth/10425/30
 */
contract AaveV3EthcbETHPayload is AaveV3ListingEthereum {
  address constant CBETH = 0xBe9895146f7AF43049ca1c1AE358B0541Ea49704;
  address constant CBETH_USD_FEED =
    address(0x5f4d15d761528c57a5C30c43c1DAb26Fc5452731);

  constructor()
    AaveV3ListingEthereum(
      IGenericV3ListingEngine(AaveV3Ethereum.LISTING_ENGINE)
    )
  {}

  function getAllConfigs()
    public
    pure
    override
    returns (IGenericV3ListingEngine.Listing[] memory)
  {
    IGenericV3ListingEngine.Listing[]
      memory listings = new IGenericV3ListingEngine.Listing[](1);

    listings[0] = IGenericV3ListingEngine.Listing({
      asset: CBETH,
      assetSymbol: 'cbETH',
      priceFeed: CBETH_USD_FEED,
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