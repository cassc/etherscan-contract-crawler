// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

struct ReserveData {
    ReserveConfigurationMap configuration;
    uint128 liquidityIndex; //ray
    uint128 currentLiquidityRate; //ray
    uint128 variableBorrowIndex; //ray
    uint128 currentVariableBorrowRate; //ray
    uint128 currentStableBorrowRate; //ray
    uint40 lastUpdateTimestamp;
    uint16 id;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    address interestRateStrategyAddress;
    uint128 accruedToTreasury;
    uint128 unbacked;
    uint128 isolationModeTotalDebt;
}
struct UserConfigurationMap {
    uint256 data;
}

struct EModeCategory {
    // each eMode category has a custom ltv and liquidation threshold
    uint16 ltv;
    uint16 liquidationThreshold;
    uint16 liquidationBonus;
    // each eMode category may or may not have a custom oracle to override the individual assets price oracles
    address priceSource;
    string label;
}

struct ReserveConfigurationMap {
    uint256 data;
}

//IUiIncentives
struct AggregatedReserveIncentiveData {
    address underlyingAsset;
    IncentiveData aIncentiveData;
    IncentiveData vIncentiveData;
    IncentiveData sIncentiveData;
}

struct IncentiveData {
    address tokenAddress;
    address incentiveControllerAddress;
    RewardInfo[] rewardsTokenInformation;
}

struct RewardInfo {
    string rewardTokenSymbol;
    address rewardTokenAddress;
    address rewardOracleAddress;
    uint256 emissionPerSecond;
    uint256 incentivesLastUpdateTimestamp;
    uint256 tokenIncentivesIndex;
    uint256 emissionEndTimestamp;
    int256 rewardPriceFeed;
    uint8 rewardTokenDecimals;
    uint8 precision;
    uint8 priceFeedDecimals;
}

struct UserReserveIncentiveData {
    address underlyingAsset;
    UserIncentiveData aTokenIncentivesUserData;
    UserIncentiveData vTokenIncentivesUserData;
    UserIncentiveData sTokenIncentivesUserData;
}

struct UserIncentiveData {
    address tokenAddress;
    address incentiveControllerAddress;
    UserRewardInfo[] userRewardsInformation;
}

struct UserRewardInfo {
    string rewardTokenSymbol;
    address rewardOracleAddress;
    address rewardTokenAddress;
    uint256 userUnclaimedRewards;
    uint256 tokenIncentivesUserIndex;
    int256 rewardPriceFeed;
    uint8 priceFeedDecimals;
    uint8 rewardTokenDecimals;
}

//IUiDataProvider
struct BaseCurrencyInfo {
    uint256 marketReferenceCurrencyUnit;
    int256 marketReferenceCurrencyPriceInUsd;
    int256 networkBaseTokenPriceInUsd;
    uint8 networkBaseTokenPriceDecimals;
}

struct AggregatedReserveData {
    address underlyingAsset;
    string name;
    string symbol;
    uint256 decimals;
    uint256 baseLTVasCollateral;
    uint256 reserveLiquidationThreshold;
    uint256 reserveLiquidationBonus;
    uint256 reserveFactor;
    bool usageAsCollateralEnabled;
    bool borrowingEnabled;
    bool stableBorrowRateEnabled;
    bool isActive;
    bool isFrozen;
    // base data
    uint128 liquidityIndex;
    uint128 variableBorrowIndex;
    uint128 liquidityRate;
    uint128 variableBorrowRate;
    uint128 stableBorrowRate;
    uint40 lastUpdateTimestamp;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    address interestRateStrategyAddress;
    //
    uint256 availableLiquidity;
    uint256 totalPrincipalStableDebt;
    uint256 averageStableRate;
    uint256 stableDebtLastUpdateTimestamp;
    uint256 totalScaledVariableDebt;
    uint256 priceInMarketReferenceCurrency;
    address priceOracle;
    uint256 variableRateSlope1;
    uint256 variableRateSlope2;
    uint256 stableRateSlope1;
    uint256 stableRateSlope2;
    uint256 baseStableBorrowRate;
    uint256 baseVariableBorrowRate;
    uint256 optimalUsageRatio;
    // v3 only
    bool isPaused;
    bool isSiloedBorrowing;
    uint128 accruedToTreasury;
    uint128 unbacked;
    uint128 isolationModeTotalDebt;
    bool flashLoanEnabled;
    //
    uint256 debtCeiling;
    uint256 debtCeilingDecimals;
    uint8 eModeCategoryId;
    uint256 borrowCap;
    uint256 supplyCap;
    // eMode
    uint16 eModeLtv;
    uint16 eModeLiquidationThreshold;
    uint16 eModeLiquidationBonus;
    address eModePriceSource;
    string eModeLabel;
    bool borrowableInIsolation;
}

interface IPool {
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getEModeCategoryData(uint8 id) external view returns (EModeCategory memory);

    //@return emode id of the user
    function getUserEMode(address user) external view returns (uint256);

    function getReservesList() external view virtual returns (address[] memory);

    function getUserConfiguration(address user) external view returns (UserConfigurationMap memory);

    function getReserveData(address asset) external view returns (ReserveData memory);
}

interface IPriceOracleGetter {
    // @notice Returns the base currency address
    // @dev Address 0x0 is reserved for USD as base currency.
    function BASE_CURRENCY() external view returns (address);

    // @notice Returns the base currency unit
    // @dev 1 ether for ETH, 1e8 for USD.
    function BASE_CURRENCY_UNIT() external view returns (uint256);

    // @notice Returns the asset price in the base currency
    function getAssetPrice(address asset) external view returns (uint256);
}

interface IAaveIncentivesController {
    //@notice returns total(accrued+non-accrued) rewards of user for given assets
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    //@notice Returns the unclaimed rewards of the user
    function getUserUnclaimedRewards(address user) external view returns (uint256);

    // @notice Returns the user index for a specific asset
    function getUserAssetData(address user, address asset) external view returns (uint256);

    // @dev Returns the configuration of the distribution for a certain asset
    // @return The asset index, the emission per second and the last updated timestamp
    function assets(address asset)
        external
        view
        returns (
            uint128,
            uint128,
            uint256
        );
}

interface IAaveOracle is IPriceOracleGetter {
    // @notice Returns a list of prices from a list of assets addresses
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

    // @notice Returns the address of the source for an asset address
    function getSourceOfAsset(address asset) external view returns (address);

    // @notice Returns the address of the fallback oracle
    function getFallbackOracle() external view returns (address);
}

interface IPoolAddressesProvider {
    // @notice Returns the address of the Pool proxy.
    function getPool() external view returns (address);

    // @notice Returns the address of the price oracle.
    function getPriceOracle() external view returns (address);

    // @notice Returns the address of the data provider.
    function getPoolDataProvider() external view returns (address);
}

interface IPoolDataProvider {
    // @notice Returns the reserve data
    function getReserveData(address asset)
        external
        view
        returns (
            uint256 unbacked,
            uint256 accruedToTreasuryScaled,
            uint256 totalAToken,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );
}

interface IPriceOracle {
    // @notice Returns the asset price in the base currency
    function getAssetPrice(address asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
}

interface IStableDebtToken {
    // @notice Returns the stable rate of the user debt
    function getUserStableRate(address user) external view returns (uint256);
}

interface IAaveProtocolDataProvider is IPoolDataProvider {
    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    function getPaused(address asset) external view returns (bool isPaused);

    /*
     * @notice Returns whether the reserve has FlashLoans enabled or disabled
     * @param asset The address of the underlying asset of the reserve
     * @return True if FlashLoans are enabled, false otherwise
     */
    function getFlashLoanEnabled(address asset) external view returns (bool);

    function getLiquidationProtocolFee(address asset) external view returns (uint256);

    function getReserveEModeCategory(address asset) external view returns (uint256);

    function getReserveCaps(address asset) external view returns (uint256 borrowCap, uint256 supplyCap);

    // @notice Returns the debt ceiling of the reserve
    function getDebtCeiling(address asset) external view returns (uint256);

    // @notice Returns the debt ceiling decimals
    function getDebtCeilingDecimals() external pure returns (uint256);

    function getATokenTotalSupply(address asset) external view returns (uint256);

    function getReserveData(address asset)
        external
        view
        override
        returns (
            uint256 unbacked,
            uint256 accruedToTreasuryScaled,
            uint256 totalAToken,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );
}

//chainlink price feed
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestAnswer() external view returns (int256);
}

interface IERC20Detailed {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IUiIncentiveDataProviderV3 {
    function getReservesIncentivesData(IPoolAddressesProvider provider)
        external
        view
        returns (AggregatedReserveIncentiveData[] memory);

    function getUserReservesIncentivesData(IPoolAddressesProvider provider, address user)
        external
        view
        returns (UserReserveIncentiveData[] memory);

    // generic method with full data
    function getFullReservesIncentiveData(IPoolAddressesProvider provider, address user)
        external
        view
        returns (AggregatedReserveIncentiveData[] memory, UserReserveIncentiveData[] memory);
}

interface IRewardsDistributor {
    function getUserAssetData(
        address user,
        address asset,
        address reward
    ) external view returns (uint256);

    /**
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The incentivized asset
     * @param reward The reward token of the incentivized asset
     * @return The asset index, the emission per second, the last updated timestamp and the distribution end timestamp
     **/
    function getRewardsData(address asset, address reward)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev Returns the list of available reward token addresses of an incentivized asset
     * @param asset The incentivized asset
     * @return List of rewards addresses of the input asset
     **/
    function getRewardsByAsset(address asset) external view returns (address[] memory);

    /**
     * @dev Returns the list of available reward addresses
     * @return List of rewards supported in this contract
     **/
    function getRewardsList() external view returns (address[] memory);

    /**
     * @dev Returns a single rewards balance of an user 
     from contract storage state, not including virtually accrued rewards since last distribution.
     * @param user The address of the user
     * @param reward The address of the reward token
     * @return Unclaimed rewards, from storage
     **/
    function getUserUnclaimedRewardsFromStorage(address user, address reward) external view returns (uint256);

    /**
     * @dev Returns a single rewards balance of an user, including virtually accrued and unrealized claimable rewards.
     * @param assets List of incentivized assets to check eligible distributions
     * @param user The address of the user
     * @param reward The address of the reward token
     * @return The rewards amount
     **/
    function getUserRewards(
        address[] calldata assets,
        address user,
        address reward
    ) external view returns (uint256);

    /**
     * @dev Returns a list all rewards of an user, including already accrued and unrealized claimable rewards
     * @param assets List of incentivized assets to check eligible distributions
     * @param user The address of the user
     * @return The function returns a Tuple of rewards list and the unclaimed rewards list
     **/
    function getAllUserRewards(address[] calldata assets, address user)
        external
        view
        returns (address[] memory, uint256[] memory);

    /**
     * @dev Returns the decimals of an asset to calculate the distribution delta
     * @param asset The address to retrieve decimals saved at storage
     * @return The decimals of an underlying asset
     */
    function getAssetDecimals(address asset) external view returns (uint8);
}

interface IRewardsController is IRewardsDistributor {
    function getRewardOracle(address reward) external view returns (address);

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);
}