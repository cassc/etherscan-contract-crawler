// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import { DSMath } from "../../../../utils/dsmath.sol";
import { Types } from "./library/Types.sol";
import { MarketLib } from "./library/MarketLib.sol";
import { Utils } from "./library/Utils.sol";
import { DataTypes } from "./library/aave-v3-core/protocol/libraries/types/DataTypes.sol";
import { Math } from "./library/math/Math.sol";
import { WadRayMath } from "./library/math/WadRayMath.sol";
import { ReserveConfiguration } from "./library/aave-v3-core/protocol/libraries/configration/ReserveConfiguration.sol";

contract MorphoHelpers is DSMath {
    using MarketLib for Types.Market;
    using Math for uint256;
    using WadRayMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    IMorpho internal morpho = IMorpho(0x33333aea097c193e66081E930c33020272b33333);
    AaveAddressProvider addrProvider = AaveAddressProvider(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e);
    IAaveProtocolDataProvider internal protocolData =
        IAaveProtocolDataProvider(0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3);
    IPool internal pool = IPool(addrProvider.getPool());

    /**
     *@dev Returns ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function getAWethAddr() internal pure returns (address) {
        return 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;
    }

    function getChainlinkEthFeed() internal pure returns (address) {
        return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    }

    struct MorphoData {
        MarketDetail[] aaveMarketsCreated;
        bool isClaimRewardsPausedAave;
        uint256 p2pSupplyAmount; // In Base Currency
        uint256 p2pBorrowAmount; // In Base Currency
        uint256 poolSupplyAmount; // In Base Currency
        uint256 poolBorrowAmount; // In Base Currency
        uint256 totalSupplyAmount; // In Base Currency
        uint256 totalBorrowAmount; // In Base Currency
        uint256 idleSupplyAmount; // In Base Currency
    }

    struct TokenConfig {
        address aTokenAddress;
        address sDebtTokenAddress;
        address vDebtTokenAddress;
        uint256 decimals;
        uint256 tokenPriceInEth;
        uint256 tokenPriceInUsd;
        uint256 eModeCategory;
    }

    struct AaveMarketDetail {
        uint256 liquidityRate;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 totalSupplies;
        uint256 totalStableBorrows;
        uint256 totalVariableBorrows;
    }

    struct MarketDetail {
        TokenConfig config;
        uint256 avgSupplyRatePerYear;
        //in wad
        uint256 avgBorrowRatePerYear;
        //in wad
        uint256 p2pSupplyRate;
        uint256 p2pBorrowRate;
        uint256 poolSupplyRate;
        uint256 poolBorrowRate;
        uint256 totalP2PSupply;
        uint256 totalPoolSupply;
        uint256 totalIdleSupply;
        uint256 totalP2PBorrows;
        uint256 totalPoolBorrows;
        uint40 lastUpdateTimestamp;
        uint256 reserveFactor;
        // 0% = supply rate, 100% = borrow rate
        AaveMarketDetail aaveData;
        Flags flags;
    }

    struct Flags {
        bool isCreated;
        bool isSupplyPaused;
        bool isSupplyCollateralPaused;
        bool isBorrowPaused;
        bool isRepayPaused;
        bool isWithdrawPaused;
        bool isWithdrawCollateralPaused;
        bool isLiquidateCollateralPaused;
        bool isLiquidateBorrowPaused;
        bool isDeprecated;
        bool isP2PDisabled;
        bool isUnderlyingBorrowEnabled;
    }

    struct UserMarketData {
        MarketDetail marketData;
        uint256 borrowRatePerYear;
        uint256 supplyRatePerYear;
        uint256 totalSupplies;
        uint256 totalCollateral;
        uint256 totalBorrows;
        uint256 p2pBorrows;
        uint256 p2pSupplies;
        uint256 poolBorrows;
        uint256 poolSupplies;
    }

    struct UserData {
        uint256 healthFactor;
        uint256 collateralValue;
        uint256 supplyValue;
        uint256 debtValue;
        uint256 maxDebtValue;
        uint256 maxBorrowable;
        uint256 liquidationThreshold;
        UserMarketData[] marketData;
        uint256 ethPriceInUsd;
    }

    struct TokenPrice {
        uint256 priceInEth;
        uint256 priceInUsd;
    }

    function getTokensPrices(AaveAddressProvider aaveAddressProvider, address[] memory tokens)
        internal
        view
        returns (TokenPrice[] memory tokenPrices, uint256 ethPrice)
    {
        // Price of tokens in Base currency
        uint256[] memory _tokenPrices = IAaveOracle(aaveAddressProvider.getPriceOracle()).getAssetsPrices(tokens);

        // Price of ETH in Base currency
        ethPrice = uint256(ChainLinkInterface(getChainlinkEthFeed()).latestAnswer());

        tokenPrices = new TokenPrice[](_tokenPrices.length);

        for (uint256 i = 0; i < _tokenPrices.length; i++) {
            tokenPrices[i] = TokenPrice(_tokenPrices[i], wmul(_tokenPrices[i], uint256(ethPrice) * 10**10));
        }
    }

    /************************************|
    |            SUPPLY DATA             |
    |___________________________________*/

    /// @notice Morpho data for "Supply". P2P + Pool + Idle
    /// @return p2pSupplyAmount The total supplied amount matched peer-to-peer
    /// subtracting the supply delta and the idle supply on Morpho's contract (in base currency).
    /// @return poolSupplyAmount The total supplied amount on the underlying pool
    /// adding the supply delta (in base currency).
    /// @return idleSupplyAmount The total idle supply amount on the Morpho's contract (in base currency).
    /// @return totalSupplyAmount The total amount supplied through Morpho (in base currency).
    function totalSupply()
        public
        view
        returns (
            uint256 p2pSupplyAmount,
            uint256 poolSupplyAmount,
            uint256 idleSupplyAmount,
            uint256 totalSupplyAmount
        )
    {
        address[] memory marketAddresses = morpho.marketsCreated();

        uint256 underlyingPrice;
        uint256 nbMarkets = marketAddresses.length;

        for (uint256 i; i < nbMarkets; ++i) {
            address underlying = marketAddresses[i];

            DataTypes.ReserveConfigurationMap memory reserve = pool.getConfiguration(underlying);
            underlyingPrice = assetPrice(underlying, reserve.getEModeCategory());
            uint256 assetUnit = 10**reserve.getDecimals();

            (
                uint256 marketP2PSupplyAmount,
                uint256 marketPoolSupplyAmount,
                uint256 marketIdleSupplyAmount
            ) = marketSupply(underlying);

            p2pSupplyAmount += (marketP2PSupplyAmount * underlyingPrice) / assetUnit;
            poolSupplyAmount += (marketPoolSupplyAmount * underlyingPrice) / assetUnit;
            idleSupplyAmount += (marketIdleSupplyAmount * underlyingPrice) / assetUnit;
        }

        totalSupplyAmount = p2pSupplyAmount + poolSupplyAmount + idleSupplyAmount;
    }

    /// @notice Returns the supply rate per year a given user is currently experiencing on a given market.
    /// @param underlying The address of the underlying asset.
    /// @param user The user to compute the supply rate per year for.
    /// @return supplyRatePerYear The supply rate per year the user is currently experiencing (in ray).
    function supplyAPRUser(address underlying, address user) public view returns (uint256 supplyRatePerYear) {
        (uint256 balanceInP2P, uint256 balanceOnPool, ) = supplyBalanceUser(underlying, user);
        (uint256 poolSupplyRate, uint256 poolBorrowRate) = poolAPR(underlying);

        Types.Market memory market = morpho.market(underlying);
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        uint256 p2pSupplyRate = Utils.p2pSupplyAPR(
            Utils.P2PRateComputeParams({
                poolSupplyRatePerYear: poolSupplyRate,
                poolBorrowRatePerYear: poolBorrowRate,
                poolIndex: indexes.supply.poolIndex,
                p2pIndex: indexes.supply.p2pIndex,
                proportionIdle: market.getProportionIdle(),
                p2pDelta: market.deltas.supply.scaledDelta,
                p2pTotal: market.deltas.supply.scaledP2PTotal,
                p2pIndexCursor: market.p2pIndexCursor,
                reserveFactor: market.reserveFactor
            })
        );

        supplyRatePerYear = Utils.weightedRate(p2pSupplyRate, poolSupplyRate, balanceInP2P, balanceOnPool);
    }

    /// @notice Total amount deposited in supply and in collateral in Morpho.
    /// @notice Computes and returns the total distribution of supply for a given market
    /// using virtually updated indexes.
    /// @param underlying The address of the underlying asset to check.
    /// @return p2pSupply The total supplied amount (in underlying) matched peer-to-peer
    /// subtracting the supply delta and the idle supply.
    /// @return poolSupply The total supplied amount (in underlying) on the underlying pool, adding the supply delta.
    /// @return idleSupply The total idle amount (in underlying) on the Morpho contract.
    function marketSupply(address underlying)
        public
        view
        returns (
            uint256 p2pSupply,
            uint256 poolSupply,
            uint256 idleSupply
        )
    {
        Types.Market memory market = morpho.market(underlying);
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        p2pSupply = market.trueP2PSupply(indexes);
        poolSupply = IERC20(market.aToken).balanceOf(address(morpho));
        idleSupply = market.idleSupply;
    }

    /// @notice Returns the balance in underlying of a given user in a given market.
    /// @param underlying The address of the underlying asset.
    /// @param user The user to determine balances of.
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function supplyBalanceUser(address underlying, address user)
        public
        view
        returns (
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        )
    {
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        balanceInP2P = morpho.scaledP2PSupplyBalance(underlying, user).rayMulDown(indexes.supply.p2pIndex);
        balanceOnPool = morpho.scaledPoolSupplyBalance(underlying, user).rayMulDown(indexes.supply.poolIndex);
        totalBalance = balanceInP2P + balanceOnPool;
    }

    /// @notice Returns the total supply balance in underlying of a given user.
    /// @param user The user to determine balances of.
    /// @return supplyBalance The total supply balance of the user (in underlying).
    function totalSupplyBalanceUser(address[] calldata tokens, address user)
        public
        view
        returns (uint256 supplyBalance)
    {
        uint256 length = tokens.length;

        for (uint256 i = 0; i < length; i++) {
            (, , uint256 totalBalance_) = supplyBalanceUser(tokens[i], user);
            supplyBalance += totalBalance_;
        }
    }

    /************************************|
    |          COLLATERAL DATA           |
    |___________________________________*/

    /// @notice Returns the total collateral balance in underlying of a given user.
    /// @param user The user to determine balances of.
    /// @return collateralBalance The total collateral balance of the user (in underlying).
    function totalCollateralBalanceUser(address user) public view returns (uint256 collateralBalance) {
        address[] memory userCollaterals = morpho.userCollaterals(user);

        uint256 length = userCollaterals.length;

        for (uint256 i = 0; i < length; i++) {
            collateralBalance += morpho.collateralBalance(userCollaterals[i], user);
        }
    }

    /// @notice Returns the supply collateral balance of `user` on the `underlying` market (in underlying).
    function underlyingCollateralBalanceUser(address underlying, address user)
        public
        view
        returns (uint256 collateralBalance)
    {
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);
        collateralBalance = morpho.collateralBalance(underlying, user);
    }

    /// @notice Returns the list of collateral underlyings of `user`.
    function userCollaterals(address user) public view returns (address[] memory collaterals) {
        collaterals = morpho.userCollaterals(user);
    }

    /************************************|
    |            COMMON DATA             |
    |___________________________________*/

    /// @dev Computes and returns the underlying pool rates for a specific market.
    /// @param underlying The underlying pool market address.
    /// @return poolSupplyRatePerYear The market's pool supply rate per year (in ray).
    /// @return poolBorrowRatePerYear The market's pool borrow rate per year (in ray).
    function poolAPR(address underlying)
        public
        view
        returns (uint256 poolSupplyRatePerYear, uint256 poolBorrowRatePerYear)
    {
        DataTypes.ReserveData memory reserve = pool.getReserveData(underlying);
        poolSupplyRatePerYear = reserve.currentLiquidityRate;
        poolBorrowRatePerYear = reserve.currentVariableBorrowRate;
    }

    /// @notice Returns the price of a given asset.
    /// @param asset The address of the asset to get the price of.
    /// @param reserveEModeCategoryId Aave's associated reserve e-mode category.
    /// @return price The current price of the asset.
    function assetPrice(address asset, uint256 reserveEModeCategoryId) public view returns (uint256 price) {
        address priceSource;
        uint8 eModeCategoryId = uint8(morpho.eModeCategoryId());
        if (eModeCategoryId != 0 && reserveEModeCategoryId == eModeCategoryId) {
            priceSource = pool.getEModeCategoryData(eModeCategoryId).priceSource;
        }

        IAaveOracle oracle = IAaveOracle(addrProvider.getPriceOracle());

        if (priceSource != address(0)) {
            price = oracle.getAssetPrice(priceSource);
        }

        if (priceSource == address(0) || price == 0) {
            price = oracle.getAssetPrice(asset);
        }
    }

    /// @notice Computes and returns the current supply rate per year experienced on average on a given market.
    /// @param underlying The address of the underlying asset.
    /// @return avgSupplyRatePerYear The market's average supply rate per year (in ray).
    /// @return p2pSupplyRatePerYear The market's p2p supply rate per year (in ray).
    ///@return poolSupplyRatePerYear The market's pool supply rate per year (in ray).
    function avgSupplyAPR(address underlying)
        public
        view
        returns (
            uint256 avgSupplyRatePerYear,
            uint256 p2pSupplyRatePerYear,
            uint256 poolSupplyRatePerYear
        )
    {
        Types.Market memory market = morpho.market(underlying);
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        uint256 poolBorrowRatePerYear;
        (poolSupplyRatePerYear, poolBorrowRatePerYear) = poolAPR(underlying);

        p2pSupplyRatePerYear = Utils.p2pBorrowAPR(
            Utils.P2PRateComputeParams({
                poolSupplyRatePerYear: poolSupplyRatePerYear,
                poolBorrowRatePerYear: poolBorrowRatePerYear,
                poolIndex: indexes.supply.poolIndex,
                p2pIndex: indexes.supply.p2pIndex,
                proportionIdle: 0,
                p2pDelta: 0, // Simpler to account for the delta in the weighted avg.
                p2pTotal: 0,
                p2pIndexCursor: market.p2pIndexCursor,
                reserveFactor: market.reserveFactor
            })
        );

        avgSupplyRatePerYear = Utils.weightedRate(
            p2pSupplyRatePerYear,
            poolSupplyRatePerYear,
            market.trueP2PSupply(indexes),
            IERC20(market.aToken).balanceOf(address(morpho))
        );
    }

    /************************************|
    |            BORROW DATA             |
    |___________________________________*/

    /// @notice Computes and returns the total distribution of borrows through Morpho
    /// using virtually updated indexes.
    /// @return p2pBorrowAmount The total borrowed amount matched peer-to-peer
    /// subtracting the borrow delta (in base currency).
    /// @return poolBorrowAmount The total borrowed amount on the underlying pool
    /// adding the borrow delta (in base currency).
    /// @return totalBorrowAmount The total amount borrowed through Morpho (in base currency).
    function totalBorrow()
        public
        view
        returns (
            uint256 p2pBorrowAmount,
            uint256 poolBorrowAmount,
            uint256 totalBorrowAmount
        )
    {
        address[] memory marketAddresses = morpho.marketsCreated();

        uint256 underlyingPrice;
        uint256 nbMarkets = marketAddresses.length;

        for (uint256 i; i < nbMarkets; ++i) {
            address underlying = marketAddresses[i];

            DataTypes.ReserveConfigurationMap memory reserve = pool.getConfiguration(underlying);
            underlyingPrice = assetPrice(underlying, reserve.getEModeCategory());
            uint256 assetUnit = 10**reserve.getDecimals();

            (uint256 marketP2PBorrowAmount, uint256 marketPoolBorrowAmount) = marketBorrow(underlying);

            p2pBorrowAmount += (marketP2PBorrowAmount * underlyingPrice) / assetUnit;
            poolBorrowAmount += (marketPoolBorrowAmount * underlyingPrice) / assetUnit;
        }

        totalBorrowAmount = p2pBorrowAmount + poolBorrowAmount;
    }

    /// @notice Returns the borrow rate per year a given user is currently experiencing on a given market.
    /// @param underlying The address of the underlying asset.
    /// @param user The user to compute the borrow rate per year for.
    /// @return borrowRatePerYear The borrow rate per year the user is currently experiencing (in ray).
    function borrowAPRUser(address underlying, address user) public view returns (uint256 borrowRatePerYear) {
        (uint256 balanceInP2P, uint256 balanceOnPool, ) = borrowBalanceUser(underlying, user);
        (uint256 poolSupplyRate, uint256 poolBorrowRate) = poolAPR(underlying);

        Types.Market memory market = morpho.market(underlying);
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        uint256 p2pBorrowRate = Utils.p2pBorrowAPR(
            Utils.P2PRateComputeParams({
                poolSupplyRatePerYear: poolSupplyRate,
                poolBorrowRatePerYear: poolBorrowRate,
                poolIndex: indexes.borrow.poolIndex,
                p2pIndex: indexes.borrow.p2pIndex,
                proportionIdle: 0,
                p2pDelta: market.deltas.borrow.scaledDelta,
                p2pTotal: market.deltas.borrow.scaledP2PTotal,
                p2pIndexCursor: market.p2pIndexCursor,
                reserveFactor: market.reserveFactor
            })
        );

        borrowRatePerYear = Utils.weightedRate(p2pBorrowRate, poolBorrowRate, balanceInP2P, balanceOnPool);
    }

    /// @notice Computes and returns the current borrow rate per year experienced on average on a given market.
    /// @param underlying The address of the underlying asset.
    /// @return avgBorrowRatePerYear The market's average borrow rate per year (in ray).
    /// @return p2pBorrowRatePerYear The market's p2p borrow rate per year (in ray).
    ///@return poolBorrowRatePerYear The market's pool borrow rate per year (in ray).
    function avgBorrowAPR(address underlying)
        public
        view
        returns (
            uint256 avgBorrowRatePerYear,
            uint256 p2pBorrowRatePerYear,
            uint256 poolBorrowRatePerYear
        )
    {
        Types.Market memory market = morpho.market(underlying);
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        uint256 poolSupplyRatePerYear;
        (poolSupplyRatePerYear, poolBorrowRatePerYear) = poolAPR(underlying);

        p2pBorrowRatePerYear = Utils.p2pBorrowAPR(
            Utils.P2PRateComputeParams({
                poolSupplyRatePerYear: poolSupplyRatePerYear,
                poolBorrowRatePerYear: poolBorrowRatePerYear,
                poolIndex: indexes.borrow.poolIndex,
                p2pIndex: indexes.borrow.p2pIndex,
                proportionIdle: 0,
                p2pDelta: 0, // Simpler to account for the delta in the weighted avg.
                p2pTotal: 0,
                p2pIndexCursor: market.p2pIndexCursor,
                reserveFactor: market.reserveFactor
            })
        );

        avgBorrowRatePerYear = Utils.weightedRate(
            p2pBorrowRatePerYear,
            poolBorrowRatePerYear,
            market.trueP2PBorrow(indexes),
            IERC20(market.variableDebtToken).balanceOf(address(morpho))
        );
    }

    /// @notice Computes and returns the total distribution of borrows for a given market
    /// using virtually updated indexes.
    /// @param underlying The address of the underlying asset to check.
    /// @return p2pBorrow The total borrowed amount (in underlying) matched peer-to-peer, subtracting the borrow delta.
    /// @return poolBorrow The total borrowed amount (in underlying) on the underlying pool, adding the borrow delta.
    function marketBorrow(address underlying) public view returns (uint256 p2pBorrow, uint256 poolBorrow) {
        Types.Market memory market = morpho.market(underlying);
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        p2pBorrow = market.trueP2PBorrow(indexes);
        poolBorrow = IERC20(market.variableDebtToken).balanceOf(address(morpho));
    }

    /// @notice Returns the borrow balance in underlying of a given user in a given market.
    /// @param underlying The address of the underlying asset.
    /// @param user The user to determine balances of.
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function borrowBalanceUser(address underlying, address user)
        public
        view
        returns (
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        )
    {
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        balanceInP2P = morpho.scaledP2PBorrowBalance(underlying, user).rayMulUp(indexes.borrow.p2pIndex);
        balanceOnPool = morpho.scaledPoolBorrowBalance(underlying, user).rayMulUp(indexes.borrow.poolIndex);
        totalBalance = balanceInP2P + balanceOnPool;
    }

    /// @notice Returns the health factor of a given user.
    /// @param user The user of whom to get the health factor.
    /// @return The health factor of the given user (in wad).
    function healthFactor(address user) public view returns (uint256) {
        Types.LiquidityData memory liquidityData = morpho.liquidityData(user);

        return liquidityData.debt > 0 ? liquidityData.maxDebt.wadDiv(liquidityData.debt) : type(uint256).max;
    }

    function getUserData(address user, address[] memory tokens_) internal view returns (UserData memory userData_) {
        uint256 length_ = tokens_.length;

        UserMarketData[] memory marketData_ = new UserMarketData[](length_);

        (TokenPrice[] memory tokenPrices, ) = getTokensPrices(addrProvider, tokens_);

        for (uint256 i = 0; i < length_; i++) {
            marketData_[i] = getUserMarketData(user, tokens_[i], tokenPrices[i].priceInEth, tokenPrices[i].priceInUsd);
            userData_.supplyValue += marketData_[i].totalSupplies;
        }

        userData_.marketData = marketData_;

        userData_.healthFactor = healthFactor(user);

        userData_.collateralValue = totalCollateralBalanceUser(user);

        // userData_.supplyValue = totalSupplyBalance(user);

        Types.LiquidityData memory liquidityData = morpho.liquidityData(user);

        // The maximum debt value allowed to borrow (in base currency).
        userData_.maxBorrowable = liquidityData.borrowable;
        // The maximum debt value allowed before being liquidatable (in base currency).
        userData_.maxDebtValue = liquidityData.maxDebt;
        // The debt value (in base currency).
        userData_.debtValue = liquidityData.debt;

        userData_.ethPriceInUsd = uint256(ChainLinkInterface(getChainlinkEthFeed()).latestAnswer());
    }

    function getUserMarketData(
        address user,
        address underlying,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (UserMarketData memory userMarketData_) {
        userMarketData_.marketData = getMarketData(underlying, priceInEth, priceInUsd);

        // With combined P2P and pool balance
        userMarketData_.borrowRatePerYear = borrowAPRUser(underlying, user);
        userMarketData_.supplyRatePerYear = supplyAPRUser(underlying, user);

        (userMarketData_.p2pSupplies, userMarketData_.poolSupplies, userMarketData_.totalSupplies) = supplyBalanceUser(
            underlying,
            user
        );

        userMarketData_.totalCollateral = underlyingCollateralBalanceUser(underlying, user);

        (userMarketData_.p2pBorrows, userMarketData_.poolBorrows, userMarketData_.totalBorrows) = borrowBalanceUser(
            underlying,
            user
        );
    }

    function getMarketData(
        address underlying,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (MarketDetail memory marketData_) {
        (marketData_.totalP2PBorrows, marketData_.totalPoolBorrows) = marketBorrow(underlying);

        (marketData_.avgBorrowRatePerYear, marketData_.p2pBorrowRate, marketData_.poolBorrowRate) = avgBorrowAPR(
            underlying
        );

        (marketData_.totalP2PSupply, marketData_.totalPoolSupply, marketData_.totalIdleSupply) = marketSupply(
            underlying
        );

        (marketData_.avgSupplyRatePerYear, marketData_.p2pSupplyRate, marketData_.poolSupplyRate) = avgSupplyAPR(
            underlying
        );

        marketData_ = getAaveMarketData(marketData_, underlying, priceInEth, priceInUsd);
    }

    function getAaveMarketData(
        MarketDetail memory marketData_,
        address underlying,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (MarketDetail memory) {
        (
            marketData_.config.aTokenAddress,
            marketData_.config.sDebtTokenAddress,
            marketData_.config.vDebtTokenAddress
        ) = protocolData.getReserveTokensAddresses(underlying);

        marketData_.config.decimals = IERC20(marketData_.config.aTokenAddress).decimals();

        marketData_.config.tokenPriceInEth = priceInEth;
        marketData_.config.tokenPriceInUsd = priceInUsd;
        marketData_.config.eModeCategory = protocolData.getReserveEModeCategory(underlying);

        marketData_ = getLiquidityData(marketData_, underlying);

        return marketData_;
    }

    function getLiquidityData(MarketDetail memory marketData_, address asset)
        internal
        view
        returns (MarketDetail memory)
    {
        Types.Market memory market = morpho.market(asset);

        (
            ,
            marketData_.aaveData.ltv,
            marketData_.aaveData.liquidationThreshold,
            ,
            marketData_.reserveFactor,
            ,
            marketData_.flags.isUnderlyingBorrowEnabled,
            ,
            ,

        ) = protocolData.getReserveConfigurationData(asset);

        (, address sToken_, address vToken_) = protocolData.getReserveTokensAddresses(asset);

        (
            ,
            ,
            marketData_.aaveData.totalSupplies,
            marketData_.aaveData.totalStableBorrows,
            marketData_.aaveData.totalVariableBorrows,
            marketData_.aaveData.liquidityRate,
            ,
            ,
            ,
            ,
            ,
            marketData_.lastUpdateTimestamp
        ) = protocolData.getReserveData(asset);

        marketData_.flags.isCreated = MarketLib.isCreated(market);
        marketData_.flags.isSupplyPaused = MarketLib.isSupplyPaused(market);
        marketData_.flags.isSupplyCollateralPaused = MarketLib.isSupplyCollateralPaused(market);
        marketData_.flags.isBorrowPaused = MarketLib.isBorrowPaused(market);
        marketData_.flags.isRepayPaused = MarketLib.isRepayPaused(market);
        marketData_.flags.isWithdrawPaused = MarketLib.isWithdrawPaused(market);
        marketData_.flags.isWithdrawCollateralPaused = MarketLib.isWithdrawCollateralPaused(market);
        marketData_.flags.isLiquidateCollateralPaused = MarketLib.isLiquidateCollateralPaused(market);
        marketData_.flags.isLiquidateBorrowPaused = MarketLib.isLiquidateBorrowPaused(market);
        marketData_.flags.isDeprecated = MarketLib.isDeprecated(market);
        marketData_.flags.isP2PDisabled = MarketLib.isP2PDisabled(market);

        return marketData_;
    }

    // TODO: Return from a main function
    function getEmodeCategoryData(uint8 id) internal view returns (DataTypes.EModeCategory memory emodeCategoryData) {
        emodeCategoryData = pool.getEModeCategoryData(id);
    }

    function getMorphoData() internal view returns (MorphoData memory morphoData_) {
        address[] memory tokens_ = morpho.marketsCreated();

        MarketDetail[] memory aaveMarket_ = new MarketDetail[](tokens_.length);
        uint256 length_ = tokens_.length;

        (TokenPrice[] memory tokenPrices, ) = getTokensPrices(addrProvider, tokens_);

        for (uint256 i = 0; i < length_; i++) {
            aaveMarket_[i] = getMarketData(tokens_[i], tokenPrices[i].priceInEth, tokenPrices[i].priceInUsd);
        }

        morphoData_.aaveMarketsCreated = aaveMarket_;

        morphoData_.isClaimRewardsPausedAave = morpho.isClaimRewardsPaused();

        (
            morphoData_.p2pSupplyAmount,
            morphoData_.poolSupplyAmount,
            morphoData_.idleSupplyAmount,
            morphoData_.totalSupplyAmount
        ) = totalSupply();
        (morphoData_.p2pBorrowAmount, morphoData_.poolBorrowAmount, morphoData_.totalBorrowAmount) = totalBorrow();
    }

    function getUserMarkets() internal view returns (address[] memory markets_) {
        markets_ = morpho.marketsCreated();
    }
}