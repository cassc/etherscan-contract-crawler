// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import { DSMath } from "../../../../utils/dsmath.sol";

contract MorphoHelpers is DSMath {
    /**
     *@dev Returns ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function getAWethAddr() internal pure returns (address) {
        return 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    }

    function getChainlinkEthFeed() internal pure returns (address) {
        return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    }

    function getAaveProtocolDataProvider() internal pure returns (address) {
        return 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
    }

    function getAaveIncentivesController() internal pure returns (address) {
        return 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;
    }

    struct MorphoData {
        MarketDetail[] aaveMarketsCreated;
        bool isClaimRewardsPausedAave;
        uint256 p2pSupplyAmount;
        uint256 p2pBorrowAmount;
        uint256 poolSupplyAmount;
        uint256 poolBorrowAmount;
        uint256 totalSupplyAmount;
        uint256 totalBorrowAmount;
    }

    struct TokenConfig {
        address poolTokenAddress;
        address underlyingToken;
        uint256 decimals;
        uint256 tokenPriceInEth;
        uint256 tokenPriceInUsd;
    }

    struct AaveMarketDetail {
        uint256 aEmissionPerSecond;
        uint256 sEmissionPerSecond;
        uint256 vEmissionPerSecond;
        uint256 availableLiquidity;
        uint256 liquidityRate;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 totalSupplies;
        uint256 totalStableBorrows;
        uint256 totalVariableBorrows;
    }

    struct MarketDetail {
        TokenConfig config;
        uint256 avgSupplyRatePerYear; //in wad
        uint256 avgBorrowRatePerYear; //in wad
        uint256 p2pSupplyRate;
        uint256 p2pBorrowRate;
        uint256 poolSupplyRate;
        uint256 poolBorrowRate;
        uint256 totalP2PSupply;
        uint256 totalPoolSupply;
        uint256 totalP2PBorrows;
        uint256 totalPoolBorrows;
        uint256 p2pSupplyIndex;
        uint256 p2pBorrowIndex;
        uint256 poolSupplyIndex; //exchange rate of cTokens for compound
        uint256 poolBorrowIndex;
        uint256 lastUpdateTimestamp;
        uint256 p2pSupplyDelta; //The total amount of underlying ERC20 tokens supplied through Morpho,
        //stored as matched peer-to-peer but supplied on the underlying pool
        uint256 p2pBorrowDelta; //The total amount of underlying ERC20 tokens borrow through Morpho,
        //stored as matched peer-to-peer but borrowed from the underlying pool
        uint256 reserveFactor;
        uint256 p2pIndexCursor; //p2p rate position b/w supply and borrow rate, in bps,
        // 0% = supply rate, 100% = borrow rate
        AaveMarketDetail aaveData;
        Flags flags;
    }

    struct Flags {
        bool isCreated;
        bool isPaused;
        bool isPartiallyPaused;
        bool isP2PDisabled;
        bool isUnderlyingBorrowEnabled;
    }

    struct UserMarketData {
        MarketDetail marketData;
        uint256 borrowRatePerYear;
        uint256 supplyRatePerYear;
        uint256 totalSupplies;
        uint256 totalBorrows;
        uint256 p2pBorrows;
        uint256 p2pSupplies;
        uint256 poolBorrows;
        uint256 poolSupplies;
        uint256 maxWithdrawable;
        uint256 maxBorrowable;
    }

    struct UserData {
        uint256 healthFactor; //calculated by updating interest accrue indices for all markets
        uint256 collateralValue; //calculated by updating interest accrue indices for all markets
        uint256 debtValue; //calculated by updating interest accrue indices for all markets
        uint256 maxDebtValue; //calculated by updating interest accrue indices for all markets
        bool isLiquidatable;
        uint256 liquidationThreshold;
        UserMarketData[] marketData;
        uint256 ethPriceInUsd;
    }

    struct TokenPrice {
        uint256 priceInEth;
        uint256 priceInUsd;
    }

    IAaveLens internal aavelens = IAaveLens(0x01ccD53a4838e94797d0579Ab1818a834a6A3855);
    IMorpho internal aaveMorpho = IMorpho(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0);
    AaveAddressProvider addrProvider = AaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    IAave internal protocolData = IAave(getAaveProtocolDataProvider());
    IAave internal incentiveData = IAave(getAaveIncentivesController());

    function getTokensPrices(AaveAddressProvider aaveAddressProvider, address[] memory tokens)
        internal
        view
        returns (TokenPrice[] memory tokenPrices, uint256 ethPrice)
    {
        uint256[] memory _tokenPrices = AavePriceOracle(aaveAddressProvider.getPriceOracle()).getAssetsPrices(tokens);
        ethPrice = uint256(ChainLinkInterface(getChainlinkEthFeed()).latestAnswer());
        tokenPrices = new TokenPrice[](_tokenPrices.length);
        for (uint256 i = 0; i < _tokenPrices.length; i++) {
            tokenPrices[i] = TokenPrice(_tokenPrices[i], wmul(_tokenPrices[i], uint256(ethPrice) * 10**10));
        }
    }

    function getLiquidatyData(
        MarketDetail memory marketData_,
        address poolTokenAddress_,
        address asset
    ) internal view returns (MarketDetail memory) {
        (
            ,
            ,
            ,
            ,
            ,
            marketData_.reserveFactor,
            marketData_.p2pIndexCursor,
            marketData_.aaveData.ltv,
            marketData_.aaveData.liquidationThreshold,
            marketData_.aaveData.liquidationBonus,

        ) = aavelens.getMarketConfiguration(poolTokenAddress_);

        (, address sToken_, address vToken_) = protocolData.getReserveTokensAddresses(asset);

        (, marketData_.aaveData.aEmissionPerSecond, ) = incentiveData.getAssetData(asset);
        (, marketData_.aaveData.sEmissionPerSecond, ) = incentiveData.getAssetData(sToken_);
        (, marketData_.aaveData.vEmissionPerSecond, ) = incentiveData.getAssetData(vToken_);
        (
            marketData_.aaveData.availableLiquidity,
            marketData_.aaveData.totalStableBorrows,
            marketData_.aaveData.totalVariableBorrows,
            marketData_.aaveData.liquidityRate,
            ,
            ,
            ,
            ,
            ,

        ) = protocolData.getReserveData(asset);
        return marketData_;
    }

    function getAaveHelperData(
        MarketDetail memory marketData_,
        address poolTokenAddress_,
        address token_
    ) internal view returns (MarketDetail memory) {
        (, , , , , , marketData_.flags.isUnderlyingBorrowEnabled, , , ) = protocolData.getReserveConfigurationData(
            token_
        );
        marketData_.aaveData.totalSupplies = IAToken(poolTokenAddress_).totalSupply();
        return marketData_;
    }

    function getAaveMarketData(
        MarketDetail memory marketData_,
        address poolTokenAddress_,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (MarketDetail memory) {
        marketData_.config.poolTokenAddress = poolTokenAddress_;
        marketData_.config.tokenPriceInEth = priceInEth;
        marketData_.config.tokenPriceInUsd = priceInUsd;
        (
            marketData_.config.underlyingToken,
            marketData_.flags.isCreated,
            marketData_.flags.isP2PDisabled,
            marketData_.flags.isPaused,
            marketData_.flags.isPartiallyPaused,
            ,
            ,
            ,
            ,
            ,
            marketData_.config.decimals
        ) = aavelens.getMarketConfiguration(poolTokenAddress_);

        marketData_ = getLiquidatyData(marketData_, poolTokenAddress_, marketData_.config.underlyingToken);
        marketData_ = getAaveHelperData(marketData_, poolTokenAddress_, marketData_.config.underlyingToken);

        return marketData_;
    }

    function getMarketData(
        address poolTokenAddress,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (MarketDetail memory marketData_) {
        marketData_ = getAaveMarketData(marketData_, poolTokenAddress, priceInEth, priceInUsd);

        (
            marketData_.avgSupplyRatePerYear,
            marketData_.avgBorrowRatePerYear,
            marketData_.totalP2PSupply,
            marketData_.totalP2PBorrows,
            marketData_.totalPoolSupply,
            marketData_.totalPoolBorrows
        ) = aavelens.getMainMarketData(poolTokenAddress);

        (
            marketData_.p2pSupplyRate,
            marketData_.p2pBorrowRate,
            marketData_.poolSupplyRate,
            marketData_.poolBorrowRate
        ) = aavelens.getRatesPerYear(poolTokenAddress);

        (
            marketData_.p2pSupplyIndex,
            marketData_.p2pBorrowIndex,
            marketData_.poolSupplyIndex,
            marketData_.poolBorrowIndex,
            marketData_.lastUpdateTimestamp,
            marketData_.p2pSupplyDelta,
            marketData_.p2pBorrowDelta
        ) = aavelens.getAdvancedMarketData(poolTokenAddress);

        // (
        //     marketData_.updatedP2PSupplyIndex,
        //     marketData_.updatedP2PBorrowIndex,
        //     marketData_.updatedPoolSupplyIndex,
        //     marketData_.updatedPoolBorrowIndex
        // ) = aavelens.getIndexes(poolTokenAddress);
    }

    function getUserMarketData(
        address user,
        address poolTokenAddress,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (UserMarketData memory userMarketData_) {
        userMarketData_.marketData = getMarketData(poolTokenAddress, priceInEth, priceInUsd);
        (userMarketData_.p2pBorrows, userMarketData_.poolBorrows, userMarketData_.totalBorrows) = aavelens
            .getCurrentBorrowBalanceInOf(poolTokenAddress, user);
        (userMarketData_.p2pSupplies, userMarketData_.poolSupplies, userMarketData_.totalSupplies) = aavelens
            .getCurrentSupplyBalanceInOf(poolTokenAddress, user);
        userMarketData_.borrowRatePerYear = aavelens.getCurrentUserBorrowRatePerYear(poolTokenAddress, user);
        userMarketData_.supplyRatePerYear = aavelens.getCurrentUserSupplyRatePerYear(poolTokenAddress, user);

        (userMarketData_.maxWithdrawable, userMarketData_.maxBorrowable) = aavelens.getUserMaxCapacitiesForAsset(
            user,
            poolTokenAddress
        );
    }

    function getUserMarkets(address user) internal view returns (address[] memory userMarkets_) {
        userMarkets_ = aavelens.getEnteredMarkets(user);
    }

    function getUserData(address user, address[] memory poolTokenAddresses)
        internal
        view
        returns (UserData memory userData_)
    {
        uint256 length_ = poolTokenAddresses.length;
        address[] memory tokens_ = getUnderlyingAssets(poolTokenAddresses);

        UserMarketData[] memory marketData_ = new UserMarketData[](length_);
        (TokenPrice[] memory tokenPrices, uint256 ethPrice) = getTokensPrices(addrProvider, tokens_);

        for (uint256 i = 0; i < length_; i++) {
            marketData_[i] = getUserMarketData(
                user,
                poolTokenAddresses[i],
                tokenPrices[i].priceInEth,
                tokenPrices[i].priceInUsd
            );
        }

        userData_.marketData = marketData_;
        // uint256 unclaimedRewards;

        userData_.healthFactor = aavelens.getUserHealthFactor(user);
        (
            userData_.collateralValue,
            userData_.maxDebtValue,
            userData_.liquidationThreshold,
            userData_.debtValue
        ) = aavelens.getUserBalanceStates(user);
        userData_.isLiquidatable = aavelens.isLiquidatable(user);
        userData_.ethPriceInUsd = ethPrice;
    }

    function getUnderlyingAssets(address[] memory atokens_) internal view returns (address[] memory tokens_) {
        uint256 length_ = atokens_.length;
        tokens_ = new address[](length_);

        for (uint256 i = 0; i < length_; i++) {
            tokens_[i] = IAToken(atokens_[i]).UNDERLYING_ASSET_ADDRESS();
        }
    }

    function getMorphoData() internal view returns (MorphoData memory morphoData_) {
        address[] memory aaveMarkets_ = aavelens.getAllMarkets();
        address[] memory tokens_ = getUnderlyingAssets(aaveMarkets_);

        MarketDetail[] memory aaveMarket_ = new MarketDetail[](aaveMarkets_.length);
        uint256 length_ = aaveMarkets_.length;

        (TokenPrice[] memory tokenPrices, uint256 ethPrice) = getTokensPrices(addrProvider, tokens_);

        for (uint256 i = 0; i < length_; i++) {
            aaveMarket_[i] = getMarketData(aaveMarkets_[i], tokenPrices[i].priceInEth, tokenPrices[i].priceInUsd);
        }

        morphoData_.aaveMarketsCreated = aaveMarket_;

        morphoData_.isClaimRewardsPausedAave = aaveMorpho.isClaimRewardsPaused();

        (morphoData_.p2pSupplyAmount, morphoData_.poolSupplyAmount, morphoData_.totalSupplyAmount) = aavelens
            .getTotalSupply();
        (morphoData_.p2pBorrowAmount, morphoData_.poolBorrowAmount, morphoData_.totalBorrowAmount) = aavelens
            .getTotalBorrow();
    }
}