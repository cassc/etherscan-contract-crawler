// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenericV3ListingEngine {
  /**
   * @dev Required for naming of a/v/s tokens
   * Example:
   * PoolContext({
   *   networkName: 'Polygon',
   *   networkAbbreviation: 'Pol'
   * })
   */
  struct PoolContext {
    string networkName;
    string networkAbbreviation;
  }

  /**
   * @dev Example (mock addresses):
   * Listing({
   *   asset: 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9,
   *   assetSymbol: 'AAVE',
   *   priceFeed: 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9,
   *   rateStrategy: 0x03733F4E008d36f2e37F0080fF1c8DF756622E6F,
   *   enabledToBorrow: true,
   *   flashloanable: true,
   *   stableRateModeEnabled: false,
   *   borrowableInIsolation: true,
   *   withSiloedBorrowing:, false,
   *   ltv: 70_50, // 70.5%
   *   liqThreshold: 76_00, // 76%
   *   liqBonus: 5_00, // 5%
   *   reserveFactor: 10_00, // 10%
   *   supplyCap: 100_000, // 100k AAVE
   *   borrowCap: 60_000, // 60k AAVE
   *   debtCeiling: 100_000, // 100k USD
   *   liqProtocolFee: 10_00, // 10%
   *   eModeCategory: 0, // No category
   * }
   */
  struct Listing {
    address asset;
    string assetSymbol;
    address priceFeed;
    address rateStrategy; // Mandatory, no matter if enabled for borrowing or not
    bool enabledToBorrow;
    bool stableRateModeEnabled; // Only considered is enabledToBorrow == true
    bool borrowableInIsolation; // Only considered is enabledToBorrow == true
    bool withSiloedBorrowing; // Only considered if enabledToBorrow == true
    bool flashloanable; // Independent from enabled to borrow: an asset can be flashloanble and not enabled to borrow
    uint256 ltv; // Only considered if liqThreshold > 0
    uint256 liqThreshold; // If `0`, the asset will not be enabled as collateral
    uint256 liqBonus; // Only considered if liqThreshold > 0
    uint256 reserveFactor; // Only considered if enabledToBorrow == true
    uint256 supplyCap; // Always configured
    uint256 borrowCap; // Always configured, no matter if enabled for borrowing or not
    uint256 debtCeiling; // Only considered if liqThreshold > 0
    uint256 liqProtocolFee; // Only considered if liqThreshold > 0
    uint8 eModeCategory; // If `O`, no eMode category will be set
  }

  struct AssetsConfig {
    address[] ids;
    Basic[] basics;
    Borrow[] borrows;
    Collateral[] collaterals;
    Caps[] caps;
  }

  struct Basic {
    string assetSymbol;
    address priceFeed;
    address rateStrategy; // Mandatory, no matter if enabled for borrowing or not
  }

  struct Borrow {
    bool enabledToBorrow; // Main config flag, if false, some of the other fields will not be considered
    bool flashloanable;
    bool stableRateModeEnabled;
    bool borrowableInIsolation;
    bool withSiloedBorrowing;
    uint256 reserveFactor; // With 2 digits precision, `10_00` for 10%. Should be positive and < 100_00
  }

  struct Collateral {
    uint256 ltv; // Only considered if liqThreshold > 0. With 2 digits precision, `10_00` for 10%. Should be lower than liquidationThreshold
    uint256 liqThreshold; // If `0`, the asset will not be enabled as collateral. Same format as ltv, and should be higher
    uint256 liqBonus; // Only considered if liqThreshold > 0. Same format as ltv
    uint256 debtCeiling; // Only considered if liqThreshold > 0. In USD and with 2 digits for decimals, e.g. 10_000_00 for 10k
    uint256 liqProtocolFee; // Only considered if liqThreshold > 0. Same format as ltv
    uint8 eModeCategory;
  }

  struct Caps {
    uint256 supplyCap; // Always configured. In "big units" of the asset, and no decimals. 100 for 100 ETH supply cap
    uint256 borrowCap; // Always configured, no matter if enabled for borrowing or not. Same format as supply cap
  }

  /**
   * @notice Performs a full listing of an asset in the Aave pool configured in this engine instance
   * @param context `PoolContext` struct, effectively meta-data for naming of a/v/s tokens.
   *   More information on the documentation of the struct.
   * @param listings `Listing[]` list of declarative configs for every aspect of the asset listing.
   *   More information on the documentation of the struct.
   */
  function listAssets(PoolContext memory context, Listing[] memory listings) external;
}