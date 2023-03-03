// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';
import {IGenericV3ListingEngine, AaveV3ListingEthereum} from 'aave-helpers/v3-listing-engine/AaveV3ListingEthereum.sol';

/**
 * @title List CRV on AaveV3Ethereum
 * @author Llama
 * @dev This proposal lists CRV on Aave V3 Ethereum
 * Governance: https://governance.aave.com/t/arfc-add-crv-to-ethereum-v3/11532
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xa0b5336692735fb4288537646aec5819cb4cbf01fc3a8a7cb06c9e62db708055
 */
contract AaveV3EthAddCRVPoolPayload is AaveV3ListingEthereum {
  address public constant INTEREST_RATE_STRATEGY = 0x76884cAFeCf1f7d4146DA6C4053B18B76bf6ED14;
  address public constant CRV_USD_FEED = 0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f;

  constructor() AaveV3ListingEthereum(IGenericV3ListingEngine(AaveV3Ethereum.LISTING_ENGINE)) {}

  function getAllConfigs() public pure override returns (IGenericV3ListingEngine.Listing[] memory) {
    IGenericV3ListingEngine.Listing[] memory listings = new IGenericV3ListingEngine.Listing[](1);

    listings[0] = IGenericV3ListingEngine.Listing({
      asset: AaveV2EthereumAssets.CRV_UNDERLYING,
      assetSymbol: 'CRV',
      priceFeed: CRV_USD_FEED,
      rateStrategy: INTEREST_RATE_STRATEGY,
      enabledToBorrow: true,
      stableRateModeEnabled: false,
      borrowableInIsolation: false,
      withSiloedBorrowing: false,
      flashloanable: true,
      ltv: 55_00,
      liqThreshold: 61_00,
      liqBonus: 8_30,
      reserveFactor: 20_00,
      supplyCap: 62_500_000,
      borrowCap: 7_700_000,
      debtCeiling: 20_900_000_00,
      liqProtocolFee: 10_00,
      eModeCategory: 0
    });

    return listings;
  }
}