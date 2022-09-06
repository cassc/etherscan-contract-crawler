// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract CompoundIIIHelpers is DSMath {
    /**
     *@dev Returns ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function getCometRewardsAddress() internal pure returns (address) {
        return 0x1B0e765F6224C21223AeA2af16c1C46E38885a40;
    }

    function getConfiguratorAddress() internal pure returns (address) {
        return 0xcFC1fA6b7ca982176529899D99af6473aD80DF4F;
    }

    struct BaseAssetInfo {
        address token;
        address priceFeed;
        uint256 price;
        uint8 decimals;
        ///@dev scale for base asset i.e. (10 ** decimals)
        uint64 mantissa;
        ///@dev The scale for base index (depends on time/rate scales, not base token) -> 1e15
        uint64 indexScale;
        ///@dev An index for tracking participation of accounts that supply the base asset.
        uint64 trackingSupplyIndex;
        ///@dev An index for tracking participation of accounts that borrow the base asset.
        uint64 trackingBorrowIndex;
    }

    struct Scales {
        ///@dev liquidation factor, borrow factor scale
        uint64 factorScale;
        ///@dev scale for USD prices
        uint64 priceScale;
        ///@dev The scale for the index tracking protocol rewards, useful in calculating rewards APR
        uint64 trackingIndexScale;
    }

    struct Token {
        uint8 offset;
        uint8 decimals;
        address token;
        string symbol;
        ///@dev 10**decimals
        uint256 scale;
    }

    struct AssetData {
        Token token;
        ///@dev token's priceFeed
        address priceFeed;
        ///@dev answer as per latestRoundData from the priceFeed scaled by priceScale
        uint256 price;
        ///@dev The collateral factor(decides how much each collateral can increase borrowing capacity of user),
        //integer representing the decimal value scaled up by 10 ^ 18.
        uint64 borrowCollateralFactor;
        ///@dev sets the limits for account's borrow balance,
        //integer representing the decimal value scaled up by 10 ^ 18.
        uint64 liquidateCollateralFactor;
        ///@dev liquidation penalty deducted from account's balance upon absorption
        uint64 liquidationFactor;
        ///@dev integer scaled up by 10 ^ decimals
        uint128 supplyCapInWei;
        ///@dev  current amount of collateral that all accounts have supplied
        uint128 totalCollateralInWei;
    }

    struct AccountFlags {
        ///@dev flag indicating whether the user's position is liquidatable
        bool isLiquidatable;
        ///@dev flag indicating whether an account has enough collateral to borrow
        bool isBorrowCollateralized;
    }

    struct MarketFlags {
        bool isAbsorbPaused;
        bool isBuyPaused;
        bool isSupplyPaused;
        bool isTransferPaused;
        bool isWithdrawPaused;
    }

    struct UserCollateralData {
        Token token;
        ///@dev current positive base balance of an account or zero
        uint256 suppliedBalanceInBase;
        uint256 suppliedBalanceInAsset;
    }

    struct RewardsConfig {
        address token;
        uint64 rescaleFactor;
        bool shouldUpScale;
        ///@dev The minimum amount of base principal wei for rewards to accrue.
        //The minimum amount of base asset supplied to the protocol in order for accounts to accrue rewards.
        uint104 baseMinForRewardsInBase;
    }

    struct UserRewardsData {
        address rewardToken;
        uint8 rewardTokenDecimals;
        uint256 amountOwedInWei;
        uint256 amountClaimedInWei;
    }

    struct UserData {
        ///@dev principal value the amount of base asset that the account has supplied (greater than zero)
        //or owes (less than zero) to the protocol.
        int104 principalInBase;
        ///@dev the base balance of supplies with interest, 0 for borrowing case or no supplies
        uint256 suppliedBalanceInBase;
        ///@dev the borrow base balance including interest, for non-negative base asset balance value is 0
        uint256 borrowedBalanceInBase;
        ///@dev the assets which are supplied as collateral in packed form
        uint16 assetsIn;
        ///@dev index tracking user's position
        uint64 accountTrackingIndex;
        ///@dev amount of reward token accrued based on usage of the base asset within the protocol
        //for the specified account, scaled up by 10 ^ 6.
        uint64 interestAccruedInBase;
        uint256 userNonce;
        // int256 borrowableAmount;
        // uint256 healthFactor;
        UserRewardsData[] rewards;
        AccountFlags flags;
    }

    struct MarketConfig {
        uint8 assetCount;
        ///@dev the per second supply rate as the decimal representation of a percentage scaled up by 10 ^ 18.
        uint64 supplyRateInPercentWei;
        uint64 borrowRateInPercentWei;
        ///@dev for rewards APR calculation
        //The speed at which supply rewards are tracked (in trackingIndexScale)
        uint64 baseTrackingSupplySpeed;
        ///@dev  The speed at which borrow rewards are tracked (in trackingIndexScale)
        uint64 baseTrackingBorrowSpeed;
        ///@dev total protocol reserves
        int256 reservesInBase;
        ///@dev Fraction of the liquidation penalty that goes to buyers of collateral
        uint64 storeFrontPriceFactor;
        ///@dev minimum borrow amount
        uint104 baseBorrowMinInBase;
        //amount of reserves allowed before absorbed collateral is no longer sold by the protocol
        uint104 targetReservesInBase;
        uint104 totalSupplyInBase;
        uint104 totalBorrowInBase;
        uint256 utilization;
        BaseAssetInfo baseToken;
        Scales scales;
        RewardsConfig[] rewardConfig;
        AssetData[] assets;
    }

    struct PositionData {
        UserData userData;
        UserCollateralData[] collateralData;
    }

    ICometRewards internal cometRewards = ICometRewards(getCometRewardsAddress());
    ICometConfig internal cometConfig = ICometConfig(getConfiguratorAddress());

    function getBaseTokenInfo(IComet _comet) internal view returns (BaseAssetInfo memory baseAssetInfo) {
        baseAssetInfo.token = _comet.baseToken();
        baseAssetInfo.priceFeed = _comet.baseTokenPriceFeed();
        baseAssetInfo.price = _comet.getPrice(baseAssetInfo.priceFeed);
        baseAssetInfo.decimals = _comet.decimals();
        baseAssetInfo.mantissa = _comet.baseScale();
        baseAssetInfo.indexScale = _comet.baseIndexScale();

        TotalsBasic memory indices = _comet.totalsBasic();
        baseAssetInfo.trackingSupplyIndex = indices.trackingSupplyIndex;
        baseAssetInfo.trackingBorrowIndex = indices.trackingBorrowIndex;
    }

    function getScales(IComet _comet) internal view returns (Scales memory scales) {
        scales.factorScale = _comet.factorScale();
        scales.priceScale = _comet.priceScale();
        scales.trackingIndexScale = _comet.trackingIndexScale();
    }

    function getMarketFlags(IComet _comet) internal view returns (MarketFlags memory flags) {
        flags.isAbsorbPaused = _comet.isAbsorbPaused();
        flags.isBuyPaused = _comet.isBuyPaused();
        flags.isSupplyPaused = _comet.isSupplyPaused();
        flags.isWithdrawPaused = _comet.isWithdrawPaused();
        flags.isTransferPaused = _comet.isWithdrawPaused();
    }

    function getRewardsConfig(address cometMarket) internal view returns (RewardsConfig memory rewards) {
        RewardConfig memory _rewards = cometRewards.rewardConfig(cometMarket);
        rewards.token = _rewards.token;
        rewards.rescaleFactor = _rewards.rescaleFactor;
        rewards.shouldUpScale = _rewards.shouldUpscale;
        rewards.baseMinForRewardsInBase = IComet(cometMarket).baseMinForRewards();
    }

    function getMarketAssets(IComet _comet, uint8 length) internal view returns (AssetData[] memory assets) {
        assets = new AssetData[](length);
        for (uint8 i = 0; i < length; i++) {
            AssetInfo memory asset;
            Token memory _token;
            AssetData memory _asset;
            asset = _comet.getAssetInfo(i);

            TokenInterface token = TokenInterface(asset.asset);
            _token.offset = asset.offset;
            _token.token = asset.asset;
            _token.symbol = token.symbol();
            _token.decimals = token.decimals();
            _token.scale = asset.scale;

            _asset.token = _token;
            _asset.priceFeed = asset.priceFeed;
            _asset.price = _comet.getPrice(asset.priceFeed);
            _asset.borrowCollateralFactor = asset.borrowCollateralFactor;
            _asset.liquidateCollateralFactor = asset.liquidateCollateralFactor;
            _asset.liquidationFactor = asset.liquidationFactor;
            _asset.supplyCapInWei = asset.supplyCap;
            _asset.totalCollateralInWei = _comet.totalsCollateral(asset.asset).totalSupplyAsset;

            assets[i] = _asset;
        }
    }

    function getMarketConfig(address cometMarket) internal view returns (MarketConfig memory market) {
        IComet _comet = IComet(cometMarket);
        market.utilization = _comet.getUtilization();
        market.assetCount = _comet.numAssets();
        market.supplyRateInPercentWei = _comet.getSupplyRate(market.utilization);
        market.borrowRateInPercentWei = _comet.getBorrowRate(market.utilization);
        market.baseTrackingSupplySpeed = _comet.baseTrackingSupplySpeed();
        market.baseTrackingBorrowSpeed = _comet.baseTrackingBorrowSpeed();
        market.reservesInBase = _comet.getReserves();
        market.storeFrontPriceFactor = _comet.storeFrontPriceFactor();
        market.baseBorrowMinInBase = _comet.baseBorrowMin();
        market.targetReservesInBase = _comet.targetReserves();
        market.totalSupplyInBase = _comet.totalSupply();
        market.totalBorrowInBase = _comet.totalBorrow();

        market.baseToken = getBaseTokenInfo(_comet);
        market.scales = getScales(_comet);

        market.rewardConfig = new RewardsConfig[](1);
        market.rewardConfig[0] = getRewardsConfig(cometMarket);
        market.assets = getMarketAssets(_comet, market.assetCount);
    }

    function currentValue(
        int104 principalValue,
        uint64 baseSupplyIndex,
        uint64 baseBorrowIndex,
        uint64 baseIndexScale
    ) internal view returns (int104) {
        if (principalValue >= 0) {
            return int104((uint104(principalValue) * baseSupplyIndex) / uint64(baseIndexScale));
        } else {
            return -int104((uint104(principalValue) * baseBorrowIndex) / uint64(baseIndexScale));
        }
    }

    function isAssetIn(uint16 assetsIn, uint8 assetOffset) internal pure returns (bool) {
        return (assetsIn & (uint16(1) << assetOffset) != 0);
    }

    function getBorrowableAmount(address account, address cometAddress) public returns (int256) {
        IComet _comet = IComet(cometAddress);
        UserBasic memory _userBasic = _comet.userBasic(account);
        TotalsBasic memory _totalsBasic = _comet.totalsBasic();
        uint8 _numAssets = _comet.numAssets();
        address baseTokenPriceFeed = _comet.baseTokenPriceFeed();

        int256 amount_ = int256(
            (currentValue(
                _userBasic.principal,
                _totalsBasic.baseSupplyIndex,
                _totalsBasic.baseBorrowIndex,
                _comet.baseIndexScale()
            ) * int256(_comet.getPrice(baseTokenPriceFeed))) / int256(1e8)
        );

        for (uint8 i = 0; i < _numAssets; i++) {
            if (isAssetIn(_userBasic.assetsIn, i)) {
                AssetInfo memory asset = _comet.getAssetInfo(i);
                UserCollateral memory coll = _comet.userCollateral(account, asset.asset);
                uint256 newAmount = (uint256(coll.balance) * _comet.getPrice(asset.priceFeed)) / 1e8;
                amount_ += int256((newAmount * asset.borrowCollateralFactor) / 1e18);
            }
        }

        return amount_;
    }

    function getAccountFlags(address account, IComet _comet) internal view returns (AccountFlags memory flags) {
        flags.isLiquidatable = _comet.isLiquidatable(account);
        flags.isBorrowCollateralized = _comet.isBorrowCollateralized(account);
    }

    function getCollateralData(
        address account,
        IComet _comet,
        uint8[] memory offsets
    ) internal returns (UserCollateralData[] memory _collaterals, address[] memory collateralAssets) {
        UserBasic memory _userBasic = _comet.userBasic(account);
        uint16 _assetsIn = _userBasic.assetsIn;
        uint8 numAssets = uint8(offsets.length);
        Token memory _token;
        uint8 _length = 0;

        for (uint8 i = 0; i < numAssets; i++) {
            if (isAssetIn(_assetsIn, offsets[i])) {
                _length++;
            }
        }
        _collaterals = new UserCollateralData[](numAssets);
        collateralAssets = new address[](_length);
        uint8 j = 0;

        for (uint8 i = 0; i < numAssets; i++) {
            AssetInfo memory asset = _comet.getAssetInfo(offsets[i]);
            _token.token = asset.asset;
            _token.symbol = TokenInterface(asset.asset).symbol();
            _token.decimals = TokenInterface(asset.asset).decimals();
            _token.scale = asset.scale;
            _token.offset = asset.offset;
            uint256 suppliedAmt = uint256(_comet.userCollateral(account, asset.asset).balance);
            _collaterals[i].token = _token;
            _collaterals[i].suppliedBalanceInAsset = suppliedAmt;
            _collaterals[i].suppliedBalanceInBase = getCollateralBalanceInBase(suppliedAmt, _comet, asset.priceFeed);

            if (isAssetIn(_assetsIn, offsets[i])) {
                collateralAssets[j] = _token.token;
                j++;
            }
        }
    }

    function getCollateralBalanceInBase(
        uint256 balanceInAsset,
        IComet _comet,
        address assetPriceFeed
    ) internal view returns (uint256 suppliedBalanceInBase) {
        address basePriceFeed = _comet.baseTokenPriceFeed();
        uint256 baseAssetprice = _comet.getPrice(basePriceFeed);
        uint256 collateralPrice = _comet.getPrice(assetPriceFeed);
        suppliedBalanceInBase = div(mul(balanceInAsset, collateralPrice), baseAssetprice);
    }

    function getUserData(address account, address cometMarket) internal returns (UserData memory userData) {
        IComet _comet = IComet(cometMarket);
        userData.suppliedBalanceInBase = _comet.balanceOf(account);
        userData.borrowedBalanceInBase = _comet.borrowBalanceOf(account);
        UserBasic memory accountDataInBase = _comet.userBasic(account);
        userData.principalInBase = accountDataInBase.principal;
        userData.assetsIn = accountDataInBase.assetsIn;
        userData.accountTrackingIndex = accountDataInBase.baseTrackingIndex;
        userData.interestAccruedInBase = accountDataInBase.baseTrackingAccrued;
        userData.userNonce = _comet.userNonce(account);
        UserRewardsData memory _rewards;
        RewardOwed memory reward = cometRewards.getRewardOwed(cometMarket, account);
        _rewards.rewardToken = reward.token;
        _rewards.rewardTokenDecimals = TokenInterface(reward.token).decimals();
        _rewards.amountOwedInWei = reward.owed;
        _rewards.amountClaimedInWei = cometRewards.rewardsClaimed(cometMarket, account);

        userData.rewards = new UserRewardsData[](1);
        userData.rewards[0] = _rewards;

        userData.flags = getAccountFlags(account, _comet);

        uint8 length = _comet.numAssets();
        uint8[] memory offsets = new uint8[](length);

        for (uint8 i = 0; i < length; i++) {
            offsets[i] = i;
        }
    }

    function getHealthFactor(address account, address cometMarket) public returns (uint256 healthFactor) {
        IComet _comet = IComet(cometMarket);
        UserBasic memory _userBasic = _comet.userBasic(account);
        uint16 _assetsIn = _userBasic.assetsIn;
        uint8 numAssets = _comet.numAssets();
        uint256 sumSupplyXFactor = 0;

        for (uint8 i = 0; i < numAssets; i++) {
            if (isAssetIn(_assetsIn, i)) {
                AssetInfo memory asset = _comet.getAssetInfo(i);
                uint256 suppliedAmt = uint256(_comet.userCollateral(account, asset.asset).balance);
                sumSupplyXFactor = add(sumSupplyXFactor, mul(suppliedAmt, asset.liquidateCollateralFactor));
            }
        }

        healthFactor = div(sumSupplyXFactor, _comet.borrowBalanceOf(account));
    }

    function getCollateralAll(address account, address cometMarket)
        internal
        returns (UserCollateralData[] memory collaterals)
    {
        IComet _comet = IComet(cometMarket);
        uint8 length = _comet.numAssets();
        uint8[] memory offsets = new uint8[](length);

        for (uint8 i = 0; i < length; i++) {
            offsets[i] = i;
        }
        (collaterals, ) = getCollateralData(account, _comet, offsets);
    }

    function getAssetCollaterals(
        address account,
        address cometMarket,
        uint8[] memory offsets
    ) internal returns (UserCollateralData[] memory collaterals) {
        IComet _comet = IComet(cometMarket);
        (collaterals, ) = getCollateralData(account, _comet, offsets);
    }

    function getUserPosition(address account, address cometMarket) internal returns (UserData memory userData) {
        userData = getUserData(account, cometMarket);
    }

    function getUsedCollateralList(address account, address cometMarket) internal returns (address[] memory assets) {
        uint8 length = IComet(cometMarket).numAssets();
        uint8[] memory offsets = new uint8[](length);

        for (uint8 i = 0; i < length; i++) {
            offsets[i] = i;
        }
        (, assets) = getCollateralData(account, IComet(cometMarket), offsets);
    }
}