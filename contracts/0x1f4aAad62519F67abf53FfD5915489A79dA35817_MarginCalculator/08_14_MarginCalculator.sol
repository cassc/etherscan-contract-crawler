// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import { ONtokenInterface } from "../interfaces/ONtokenInterface.sol";
import { OracleInterface } from "../interfaces/OracleInterface.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { FPI } from "../libs/FixedPointInt256.sol";
import { MarginVault } from "../libs/MarginVault.sol";
import { ArrayAddressUtils } from "../libs/ArrayAddressUtils.sol";
import { Constants } from "./Constants.sol";

/**
 * @title MarginCalculator
 * @notice Calculator module that checks if a given vault is valid, calculates margin requirements, and settlement proceeds
 */
contract MarginCalculator is Ownable {
    using SafeMath for uint256;
    using FPI for FPI.FixedPointInt;
    using ArrayAddressUtils for address[];

    /// @dev decimals used by strike price and oracle price, onToken
    uint256 internal constant BASE = 8;

    /// @dev struct to store all needed vault details
    struct VaultDetails {
        uint256 shortAmount;
        uint256 longAmount;
        uint256 usedLongAmount;
        uint256 shortStrikePrice;
        uint256 longStrikePrice;
        uint256 expiryTimestamp;
        address shortONtoken;
        bool isPut;
        bool hasLong;
        address longONtoken;
        address underlyingAsset;
        address strikeAsset;
        address[] collateralAssets;
        uint256[] collateralAmounts;
        uint256[] reservedCollateralAmounts;
        uint256[] availableCollateralAmounts;
        uint256[] collateralsDecimals;
        uint256[] usedCollateralValues;
    }

    struct ONTokenDetails {
        address[] collaterals;
        uint256[] collateralsAmounts;
        uint256[] collateralsValues;
        uint256[] collateralsDecimals;
        address underlying;
        address strikeAsset;
        uint256 strikePrice;
        uint256 expiry;
        bool isPut;
        uint256 collaterizedTotalAmount;
    }

    /// @dev FixedPoint 0
    FPI.FixedPointInt internal ZERO = FPI.fromScaledUint(0, BASE);

    /// @dev oracle module
    OracleInterface public oracle;

    /**
     * @notice constructor
     * @param _oracle oracle module address
     */
    constructor(address _oracle, address _owner) {
        require(_oracle != address(0), "MarginCalculator: invalid oracle address");
        oracle = OracleInterface(_oracle);
        transferOwnership(_owner);
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = OracleInterface(_oracle);
    }

    /**
     * @notice get an onToken's payout/cash value after expiry, in the collateral asset
     * @param _onToken onToken address
     * @param _amount amount of the onToken to calculate the payout for, always represented in 1e8
     * @return amount of collateral to pay out for provided amount rate
     */
    function getPayout(address _onToken, uint256 _amount) public view returns (uint256[] memory) {
        // payoutsRaw is amounts of each of collateral asset in collateral asset decimals to be paid out for 1e8 of the onToken
        uint256[] memory payoutsRaw = getExpiredPayoutRate(_onToken);
        uint256[] memory payouts = new uint256[](payoutsRaw.length);

        for (uint256 i = 0; i < payoutsRaw.length; i++) {
            payouts[i] = payoutsRaw[i].mul(_amount).div(10**BASE);
        }

        return payouts;
    }

    /**
     * @notice return the cash value of an expired onToken, denominated in collateral
     * @param _onToken onToken address
     * @return collateralsPayoutRate - how much collateral can be taken out by 1 onToken unit, scaled by 1e8,
     * or how much collateral can be taken out for 1 (1e8) onToken
     */
    function getExpiredPayoutRate(address _onToken) public view returns (uint256[] memory collateralsPayoutRate) {
        require(_onToken != address(0), "MarginCalculator: Invalid token address");

        ONTokenDetails memory onTokenDetails = _getONtokenDetailsStruct(_onToken);

        require(block.timestamp >= onTokenDetails.expiry, "MarginCalculator: ONtoken not expired yet");

        // Strike - current price USDC
        FPI.FixedPointInt memory cashValueInStrike = _getExpiredCashValue(
            onTokenDetails.underlying,
            onTokenDetails.strikeAsset,
            onTokenDetails.expiry,
            onTokenDetails.strikePrice,
            onTokenDetails.isPut
        );
        uint256 onTokenTotalCollateralValue = uint256ArraySum(onTokenDetails.collateralsValues);

        // FPI.FixedPointInt memory strikePriceFpi = FPI.fromScaledUint(oToenDetails.strikePrice, BASE);
        // Amounts of collateral to transfer for 1 onToken
        collateralsPayoutRate = new uint256[](onTokenDetails.collaterals.length);

        // In case of all onToken amount was burnt
        if (onTokenTotalCollateralValue == 0) {
            return collateralsPayoutRate;
        }

        FPI.FixedPointInt memory collateraizedTotalAmount = FPI.fromScaledUint(
            onTokenDetails.collaterizedTotalAmount,
            BASE
        );
        for (uint256 i = 0; i < onTokenDetails.collaterals.length; i++) {
            // the exchangeRate was scaled by 1e8, if 1e8 onToken can take out 1 USDC, the exchangeRate is currently 1e8
            // we want to return: how much USDC units can be taken out by 1 (1e8 units) onToken

            uint256 collateralDecimals = onTokenDetails.collateralsDecimals[i];
            // Collateral value is calculated in strike asset, used BASE decimals only for convinience
            FPI.FixedPointInt memory collateralValue = FPI.fromScaledUint(onTokenDetails.collateralsValues[i], BASE);
            FPI.FixedPointInt memory collateralPayoutValueInStrike = collateralValue.mul(cashValueInStrike).div(
                FPI.fromScaledUint(onTokenTotalCollateralValue, BASE)
            );

            // Compute maximal collateral payout rate as onToken.collateralsAmounts[i] / collaterizedTotalAmount
            FPI.FixedPointInt memory maxCollateralPayoutRate = FPI
                .fromScaledUint(onTokenDetails.collateralsAmounts[i], collateralDecimals)
                .div(collateraizedTotalAmount);
            // Compute collateralPayoutRate for normal conditions
            FPI.FixedPointInt memory collateralPayoutRate = _convertAmountOnExpiryPrice(
                collateralPayoutValueInStrike,
                onTokenDetails.strikeAsset,
                onTokenDetails.collaterals[i],
                onTokenDetails.expiry
            );
            collateralsPayoutRate[i] = FPI.min(maxCollateralPayoutRate, collateralPayoutRate).toScaledUint(
                collateralDecimals,
                false
            );
        }
        return collateralsPayoutRate;
    }

    /**
     * @notice returns the amount of collateral that can be removed from an actual or a theoretical vault
     * @dev return amount is denominated in the collateral asset for the onToken in the vault, or the collateral asset in the vault
     * @param _vault theoretical vault that needs to be checked
     * @return excessCollateral - the amount by which the margin is above or below the required amount
     */
    function getExcessCollateral(MarginVault.Vault memory _vault) external view returns (uint256[] memory) {
        bool hasExpiredShort = ONtokenInterface(_vault.shortONtoken).expiryTimestamp() <= block.timestamp;

        // if the vault contains no onTokens, return the amount of collateral
        if (!hasExpiredShort) {
            return _vault.availableCollateralAmounts;
        }

        VaultDetails memory vaultDetails = _getVaultDetails(_vault);

        // This payout represents how much redeemer will get for each 1e8 of onToken. But from the vault side we should also calculate ratio
        // of amounts of each collateral provided by vault to same total amount used for mint total number of onTokens
        // For example: one vault provided [200 USDC, 0 DAI], and another vault [0 USDC, 200 DAI] for the onToken mint
        // and get payout returns [100 USDC, 100 DAI] first vault pays all the 100 USDC and the second one all the 100 DAI
        // uint256[] memory payoutsRaw = getExpiredPayoutRate(vaultDetails.shortONtoken);
        uint256[] memory onTokenCollateralsValues = ONtokenInterface(vaultDetails.shortONtoken).getCollateralsValues();
        uint256 onTokenCollaterizedTotalAmount = ONtokenInterface(vaultDetails.shortONtoken).collaterizedTotalAmount();
        uint256[] memory shortPayoutsRaw = getExpiredPayoutRate(vaultDetails.shortONtoken);

        return
            _getExcessCollateral(
                vaultDetails,
                shortPayoutsRaw,
                onTokenCollateralsValues,
                onTokenCollaterizedTotalAmount
            );
    }

    function _getExcessCollateral(
        VaultDetails memory vaultDetails,
        uint256[] memory shortPayoutsRaw,
        uint256[] memory onTokenCollateralsValues,
        uint256 onTokenCollaterizedTotalAmount
    ) internal view returns (uint256[] memory) {
        uint256[] memory longPayouts = vaultDetails.hasLong && vaultDetails.longAmount != 0
            ? getPayout(vaultDetails.longONtoken, vaultDetails.longAmount)
            : new uint256[](vaultDetails.collateralAssets.length);

        FPI.FixedPointInt memory _onTokenCollaterizedTotalAmount = FPI.fromScaledUint(
            onTokenCollaterizedTotalAmount,
            BASE
        );
        uint256[] memory _excessCollaterals = vaultDetails.collateralAmounts;
        for (uint256 i = 0; i < vaultDetails.collateralAssets.length; i++) {
            uint256 collateralValueProvidedByVault = vaultDetails.usedCollateralValues[i];
            if (collateralValueProvidedByVault == 0) {
                continue;
            }

            uint256 collateralDecimals = vaultDetails.collateralsDecimals[i];

            FPI.FixedPointInt memory totalCollateralValue = FPI
                .fromScaledUint(shortPayoutsRaw[i], collateralDecimals)
                .mul(_onTokenCollaterizedTotalAmount);

            // This ratio represents for specific collateral what part does this vault cover total collaterization of onToken by this collateral
            FPI.FixedPointInt memory vaultCollateralRatio = FPI
                .fromScaledUint(collateralValueProvidedByVault, BASE)
                .div(FPI.fromScaledUint(onTokenCollateralsValues[i], BASE));

            uint256 shortRedeemableCollateral = totalCollateralValue.mul(vaultCollateralRatio).toScaledUint(
                collateralDecimals,
                // Round down shoud be false here cause we subsctruct this value and true can lead to overflow
                false
            );
            _excessCollaterals[i] = _excessCollaterals[i].add(longPayouts[i]).sub(shortRedeemableCollateral);
        }

        return _excessCollaterals;
    }

    /**
     * @notice calculates sum of uint256 array
     * @param _array uint256[] memory
     * @return uint256 sum of all elements in _array
     */
    function uint256ArraySum(uint256[] memory _array) internal pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < _array.length; i++) {
            sum = sum.add(_array[i]);
        }
        return sum;
    }

    /**
     * @notice return the cash value of an expired onToken, denominated in strike asset
     * @dev for a call, return Max (0, underlyingPriceInStrike - onToken.strikePrice)
     * @dev for a put, return Max(0, onToken.strikePrice - underlyingPriceInStrike)
     * @param _underlying onToken underlying asset
     * @param _strike onToken strike asset
     * @param _expiryTimestamp onToken expiry timestamp
     * @param _strikePrice onToken strike price
     * @param _strikePrice true if onToken is put otherwise false
     * @return cash value of an expired onToken, denominated in the strike asset, as FPI.FixedPointInt
     */
    function _getExpiredCashValue(
        address _underlying, // WETH
        address _strike, // USDC
        uint256 _expiryTimestamp, // onToken expire
        uint256 _strikePrice, // 4000
        bool _isPut // true
    ) internal view returns (FPI.FixedPointInt memory) {
        // strike price is denominated in strike asset
        FPI.FixedPointInt memory strikePrice = FPI.fromScaledUint(_strikePrice, BASE);
        FPI.FixedPointInt memory one = FPI.fromScaledUint(1, 0);

        // calculate the value of the underlying asset in terms of the strike asset
        FPI.FixedPointInt memory underlyingPriceInStrike = _convertAmountOnExpiryPrice(
            one, // underlying price is 1 (1e27) in term of underlying
            _underlying,
            _strike,
            _expiryTimestamp
        );
        return _getCashValue(strikePrice, underlyingPriceInStrike, _isPut);
    }

    /**
     * @notice convert an amount in asset A to equivalent amount of asset B, based on a live price
     * @dev function includes the amount and applies .mul() first to increase the accuracy
     * @param _amount amount in asset A
     * @param _assetA asset A
     * @param _assetB asset B
     * @return _amount in asset B
     */
    function _convertAmountOnLivePrice(
        FPI.FixedPointInt memory _amount,
        address _assetA,
        address _assetB
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_assetA == _assetB) {
            return _amount;
        }
        uint256 priceA = oracle.getPrice(_assetA);
        uint256 priceB = oracle.getPrice(_assetB);
        // amount A * price A in USD = amount B * price B in USD
        // amount B = amount A * price A / price B
        return _amount.mul(FPI.fromScaledUint(priceA, BASE)).div(FPI.fromScaledUint(priceB, BASE));
    }

    /**
     * @notice convert an amount in asset A to equivalent amount of asset B, based on an expiry price
     * @dev function includes the amount and apply .mul() first to increase the accuracy
     * @param _amount amount in asset A
     * @param _assetA asset A
     * @param _assetB asset B
     * @return _amount in asset B
     */
    function _convertAmountOnExpiryPrice(
        FPI.FixedPointInt memory _amount, // Strike - current price USDC
        address _assetA, // strikeAsset USDC
        address _assetB, // yvUSDC
        uint256 _expiry // onToken expiry
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_assetA == _assetB) {
            return _amount;
        }
        (uint256 priceA, bool priceAFinalized) = oracle.getExpiryPrice(_assetA, _expiry);
        (uint256 priceB, bool priceBFinalized) = oracle.getExpiryPrice(_assetB, _expiry);
        require(priceAFinalized && priceBFinalized, "MarginCalculator: price at expiry not finalized yet");
        // amount A * price A in USD = amount B * price B in USD
        // amount B = amount A * price A / price B
        return _amount.mul(FPI.fromScaledUint(priceA, BASE)).div(FPI.fromScaledUint(priceB, BASE));
    }

    /**
     * @notice get vault details to save us from making multiple external calls
     * @param _vault vault struct
     * @return vault details in VaultDetails struct
     */
    function _getVaultDetails(MarginVault.Vault memory _vault) internal view returns (VaultDetails memory) {
        VaultDetails memory vaultDetails = VaultDetails(
            0, // uint256 shortAmount;
            0, // uint256 longAmount;
            0, // uint256 usedLongAmount;
            0, // uint256 shortStrikePrice;
            0, // uint256 longStrikePrice;
            0, // uint256 expiryTimestamp;
            address(0), // address shortONtoken
            false, // bool isPut;
            false, // bool hasLong;
            address(0), // address longONtoken;
            address(0), // address underlyingAsset;
            address(0), // address strikeAsset;
            new address[](0), // address[] collateralAssets;
            new uint256[](0), // uint256[] collateralAmounts;
            new uint256[](0), // uint256[] reservedCollateralAmounts;
            new uint256[](0), // uint256[] availableCollateralAmounts;
            new uint256[](0), // uint256[] collateralsDecimals;
            new uint256[](0) // uint256[] usedCollateralValues;
        );

        // check if vault has long, short onToken and collateral asset
        vaultDetails.longONtoken = _vault.longONtoken;
        vaultDetails.hasLong = _vault.longONtoken != address(0) && _vault.longAmount != 0;
        vaultDetails.shortONtoken = _vault.shortONtoken;
        vaultDetails.shortAmount = _vault.shortAmount;
        vaultDetails.longAmount = _vault.longAmount;
        vaultDetails.usedLongAmount = _vault.usedLongAmount;
        vaultDetails.collateralAmounts = _vault.collateralAmounts;
        vaultDetails.reservedCollateralAmounts = _vault.reservedCollateralAmounts;
        vaultDetails.availableCollateralAmounts = _vault.availableCollateralAmounts;
        vaultDetails.usedCollateralValues = _vault.usedCollateralValues;

        // get vault long onToken if available
        if (vaultDetails.hasLong) {
            ONtokenInterface long = ONtokenInterface(_vault.longONtoken);
            vaultDetails.longStrikePrice = long.strikePrice();
        }

        // get vault short onToken if available
        ONtokenInterface short = ONtokenInterface(_vault.shortONtoken);
        (
            vaultDetails.collateralAssets,
            ,
            ,
            vaultDetails.collateralsDecimals,
            vaultDetails.underlyingAsset,
            vaultDetails.strikeAsset,
            vaultDetails.shortStrikePrice,
            vaultDetails.expiryTimestamp,
            vaultDetails.isPut,

        ) = _getONtokenDetails(address(short));

        return vaultDetails;
    }

    /**
     * @notice if there is a short option and a long option in the vault,
     * ensure that the long option is able to be used as collateral for the short option
     * @param _vault the vault to check
     * @return true if long is marginable or false if not
     */
    function isMarginableLong(address longONtokenAddress, MarginVault.Vault memory _vault)
        external
        view
        returns (bool)
    {
        // if vault is missing a long or a short, return True
        if (_vault.longONtoken != address(0)) return true;

        // check if longCollateralAssets is same as shortCollateralAssets
        ONTokenDetails memory long = _getONtokenDetailsStruct(longONtokenAddress);
        ONTokenDetails memory short = _getONtokenDetailsStruct(_vault.shortONtoken);

        bool isSameLongCollaterals = keccak256(abi.encode(long.collaterals)) ==
            keccak256(abi.encode(short.collaterals));

        return
            block.timestamp < long.expiry &&
            _vault.longONtoken != _vault.shortONtoken &&
            isSameLongCollaterals &&
            long.underlying == short.underlying &&
            long.strikeAsset == short.strikeAsset &&
            long.expiry == short.expiry &&
            long.strikePrice != short.strikePrice &&
            long.isPut == short.isPut;
    }

    /**
     * @notice get option cash value
     * @dev this assume that the underlying price is denominated in strike asset
     * cash value = max(underlying price - strike price, 0)
     * @param _strikePrice option strike price
     * @param _underlyingPrice option underlying price
     * @param _isPut option type, true for put and false for call option
     */
    function _getCashValue(
        FPI.FixedPointInt memory _strikePrice,
        FPI.FixedPointInt memory _underlyingPrice,
        bool _isPut
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_isPut) return _strikePrice.isGreaterThan(_underlyingPrice) ? _strikePrice.sub(_underlyingPrice) : ZERO;

        return _underlyingPrice.isGreaterThan(_strikePrice) ? _underlyingPrice.sub(_strikePrice) : ZERO;
    }

    /**
     * @dev get onToken detail
     */
    function _getONtokenDetails(address _onToken)
        internal
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            address,
            address,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        ONtokenInterface onToken = ONtokenInterface(_onToken);
        return onToken.getONtokenDetails();
    }

    /**
     * @dev same as _getONtokenDetails but returns struct, usefull to avoid stack too deep
     */
    function _getONtokenDetailsStruct(address _onToken) internal view returns (ONTokenDetails memory) {
        ONTokenDetails memory onTokenDetails;
        (
            address[] memory collaterals,
            uint256[] memory collateralsAmounts,
            uint256[] memory collateralsValues,
            uint256[] memory collateralsDecimals,
            address underlying,
            address strikeAsset,
            uint256 strikePrice,
            uint256 expiry,
            bool isPut,
            uint256 collaterizedTotalAmount
        ) = _getONtokenDetails(_onToken);

        onTokenDetails.collaterals = collaterals;
        onTokenDetails.collateralsAmounts = collateralsAmounts;
        onTokenDetails.collateralsValues = collateralsValues;
        onTokenDetails.collateralsDecimals = collateralsDecimals;
        onTokenDetails.underlying = underlying;
        onTokenDetails.strikeAsset = strikeAsset;
        onTokenDetails.strikePrice = strikePrice;
        onTokenDetails.expiry = expiry;
        onTokenDetails.isPut = isPut;
        onTokenDetails.collaterizedTotalAmount = collaterizedTotalAmount;

        return onTokenDetails;
    }

    /**
     * @dev return ratio which represends how much of already used collateral will be used after burn
     * @param _vault the vault to use
     * @param _shortBurnAmount amount of shorts to burn
     */
    function getAfterBurnCollateralRatio(MarginVault.Vault memory _vault, uint256 _shortBurnAmount)
        external
        view
        returns (FPI.FixedPointInt memory, uint256)
    {
        VaultDetails memory vaultDetails = _getVaultDetails(_vault);

        return _getAfterBurnCollateralRatio(vaultDetails, _shortBurnAmount);
    }

    function _getAfterBurnCollateralRatio(VaultDetails memory _vaultDetails, uint256 _shortBurnAmount)
        internal
        view
        returns (FPI.FixedPointInt memory, uint256)
    {
        uint256 newShortAmount = _vaultDetails.shortAmount.sub(_shortBurnAmount);

        (FPI.FixedPointInt memory prevValueRequired, ) = _getValueRequired(
            _vaultDetails,
            _vaultDetails.shortAmount,
            _vaultDetails.longAmount
        );

        (FPI.FixedPointInt memory newValueRequired, FPI.FixedPointInt memory newToUseLongAmount) = _getValueRequired(
            _vaultDetails,
            newShortAmount,
            _vaultDetails.longAmount
        );

        return (
            prevValueRequired.isEqual(ZERO) ? ZERO : newValueRequired.div(prevValueRequired),
            newToUseLongAmount.toScaledUint(BASE, true)
        );
    }

    /**
     * @notice calculates maximal short amount can be minted for collateral and long in a given vault
     * @param _vault the vault to check
     */
    function getMaxShortAmount(MarginVault.Vault memory _vault) external view returns (uint256) {
        VaultDetails memory vaultDetails = _getVaultDetails(_vault);
        uint256 unusedLongAmount = vaultDetails.longAmount.sub(vaultDetails.usedLongAmount);
        uint256 one = 10**BASE;
        (FPI.FixedPointInt memory valueRequiredRate, ) = _getValueRequired(vaultDetails, one, unusedLongAmount);

        (, , FPI.FixedPointInt memory availableCollateralTotalValue) = _calculateVaultAvailableCollateralsValues(
            vaultDetails
        );
        return availableCollateralTotalValue.div(valueRequiredRate).toScaledUint(BASE, true);
    }

    /**
     * @notice calculates collateral required to mint amount of onToken for a given vault
     * @param _vault the vault to check
     * @param _shortAmount amount of short onToken to be covered by collateral
     */
    function getCollateralsToCoverShort(MarginVault.Vault memory _vault, uint256 _shortAmount)
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256
        )
    {
        VaultDetails memory vaultDetails = _getVaultDetails(_vault);

        return _getCollateralsToCoverShort(vaultDetails, _shortAmount);
    }

    /**
     * @notice calculates how much value of collaterals denominated in strike asset
     * required to mint short amount with for provided vault and long amounts available
     * @param _vaultDetails details of the vault to calculate for
     * @param _shortAmount short onToken amount to be covered
     * @param _longAmount long onToken amount that can be used to cover short
     */
    function _getValueRequired(
        VaultDetails memory _vaultDetails,
        uint256 _shortAmount,
        uint256 _longAmount
    ) internal view returns (FPI.FixedPointInt memory, FPI.FixedPointInt memory) {
        bool isPut = _vaultDetails.isPut;
        (FPI.FixedPointInt memory valueRequired, FPI.FixedPointInt memory toUseLongAmount) = isPut
            ? _getPutSpreadMarginRequired(
                _shortAmount,
                _longAmount,
                _vaultDetails.shortStrikePrice,
                _vaultDetails.longStrikePrice
            )
            : _getCallSpreadMarginRequired(
                _shortAmount,
                _longAmount,
                _vaultDetails.shortStrikePrice,
                _vaultDetails.longStrikePrice
            );

        // Convert value to strike asset for calls
        valueRequired = isPut
            ? valueRequired
            : _convertAmountOnLivePrice(valueRequired, _vaultDetails.underlyingAsset, _vaultDetails.strikeAsset);
        return (valueRequired, toUseLongAmount);
    }

    /**
     * @notice calculates collateral amounts, values required and used (including long)
     * required to mint amount of onToken for a given vault
     * @param _vaultDetails details of the vault to calculate for
     * @param _shortAmount short onToken amount to be covered
     * @return collateralsAmountsRequired collaterals amounts required to be available in vault to cover short amount
     * @return collateralsValuesRequired collaterals values (in strike asset) required to be available in vault to cover short amount
     * @return collateralsAmountsUsed collaterals amounts used in vault to cover short amount, combining  collateralsAmountsRequired and collaterals amounts used from long
     * @return collateralsValuesUsed  collaterals values (in strike asset) used to cover short amount, combining  collateralsValuesRequired and collaterals values used from long
     */
    function _getCollateralsToCoverShort(VaultDetails memory _vaultDetails, uint256 _shortAmount)
        internal
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256
        )
    {
        require(_shortAmount > 0, "amount must be greater than 0");

        uint256 unusedLongAmount = _vaultDetails.longAmount.sub(_vaultDetails.usedLongAmount);
        (FPI.FixedPointInt memory valueRequired, FPI.FixedPointInt memory toUseLongAmount) = _getValueRequired(
            _vaultDetails,
            _shortAmount,
            unusedLongAmount
        );

        (
            uint256[] memory collateralsAmountsRequired,
            ,
            uint256[] memory collateralsAmountsUsed,
            uint256[] memory collateralsValuesUsed
        ) = _getCollateralsToCoverValue(_vaultDetails, valueRequired, toUseLongAmount);

        return (
            collateralsAmountsRequired,
            collateralsAmountsUsed,
            collateralsValuesUsed,
            toUseLongAmount.toScaledUint(BASE, true)
        );
    }

    /**
     * @notice calculates vault's deposited collateral amounts and values
     * required to cover provided value (denominated in strike asset) for a given vault
     * @param _vaultDetails details of the vault to calculate for
     * @param _valueRequired value required to cover, denominated in strike asset
     * @param _toUseLongAmount long amounts that can be used to fully or partly cover the value
     * @return collateralsAmountsRequired collaterals amounts required to be available in vault to cover value required
     * @return collateralsValuesRequired collaterals values (in strike asset) required to be available in vault to cover value required
     * @return collateralsAmountsUsed collaterals amounts used in vault to cover value required, combining  collateralsAmountsRequired and collaterals amounts used from long
     * @return collateralsValuesUsed  collaterals values (in strike asset) used to cover value required, combining  collateralsValuesRequired and collaterals values used from long
     */
    function _getCollateralsToCoverValue(
        VaultDetails memory _vaultDetails,
        FPI.FixedPointInt memory _valueRequired,
        FPI.FixedPointInt memory _toUseLongAmount
    )
        internal
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        // Create "higher" variable in stack same as function argument to prevent stack too deep error
        // when accessing _valueRequired, same for _vaultDetails.collateralsDecimals
        FPI.FixedPointInt memory valueRequired = _valueRequired;

        uint256[] memory collateralsDecimals = _vaultDetails.collateralsDecimals;
        // availableCollateralsValues is how much worth each available collateral in strike asset
        // availableCollateralTotalValue - how much value totally available in vault in strike asset
        (
            FPI.FixedPointInt[] memory availableCollateralsAmounts,
            FPI.FixedPointInt[] memory availableCollateralsValues,
            FPI.FixedPointInt memory availableCollateralTotalValue
        ) = _calculateVaultAvailableCollateralsValues(_vaultDetails);
        require(
            availableCollateralTotalValue.isGreaterThanOrEqual(valueRequired),
            "Vault value is not enough to collaterize the amount"
        );

        uint256 collateralsLength = _vaultDetails.collateralAssets.length;

        // collateralsAmountsUsed - is amounts of each collateral
        // used to cover short, including collateral from long
        uint256[] memory collateralsAmountsUsed = new uint256[](collateralsLength);
        // collateralsValuesUsed - is value (in strike asset)
        // of each collateral used to cover short, including collateral from long
        uint256[] memory collateralsValuesUsed = new uint256[](collateralsLength);
        if (_vaultDetails.longONtoken != address(0)) {
            (collateralsAmountsUsed, collateralsValuesUsed) = _calculateONtokenCollaterizationsOfAmount(
                _vaultDetails.longONtoken,
                _toUseLongAmount
            );
        }

        // collateralsAmountsRequired - is amounts of each collateral
        // used to cover short which will be taken from vaults deposited collateral
        uint256[] memory collateralsAmountsRequired = new uint256[](collateralsLength);
        // collateralsValuesRequired - is values (in strike asset)
        // of each collateral used to cover short which will be taken from vaults deposited collateral
        uint256[] memory collateralsValuesRequired = new uint256[](collateralsLength);

        // collaterizationRatio reporesents how much of vaults deposited collateral will be locked for covering short
        FPI.FixedPointInt memory collaterizationRatio = valueRequired.isGreaterThan(ZERO)
            ? valueRequired.div(availableCollateralTotalValue)
            : ZERO;

        for (uint256 i = 0; i < collateralsLength; i++) {
            if (availableCollateralsValues[i].isGreaterThan(ZERO)) {
                collateralsValuesRequired[i] = availableCollateralsValues[i].mul(collaterizationRatio).toScaledUint(
                    BASE,
                    true
                );
                collateralsAmountsRequired[i] = availableCollateralsAmounts[i].mul(collaterizationRatio).toScaledUint(
                    collateralsDecimals[i],
                    true
                );
            }
            collateralsAmountsUsed[i] = collateralsAmountsUsed[i].add(collateralsAmountsRequired[i]);
            collateralsValuesUsed[i] = collateralsValuesUsed[i].add(collateralsValuesRequired[i]);
        }

        return (collateralsAmountsRequired, collateralsValuesRequired, collateralsAmountsUsed, collateralsValuesUsed);
    }

    /**
     * @notice calculates vault's available collateral amounts value and total value of all collateral
     * not including value and amounts from vault's long, values are denominated in strike asset
     * @param _vaultDetails details of the vault to calculate for
     * @return availableCollateralsAmounts - amounts of collaterals available in vault
     * @return availableCollateralsValues - how much worth available vaults collateral in strike asset
     * @return availableCollateralTotalValue - how much value totally available in vault in valueAsset
     */
    function _calculateVaultAvailableCollateralsValues(VaultDetails memory _vaultDetails)
        internal
        view
        returns (
            FPI.FixedPointInt[] memory,
            FPI.FixedPointInt[] memory,
            FPI.FixedPointInt memory
        )
    {
        address _strikeAsset = _vaultDetails.strikeAsset;
        address[] memory _collateralAssets = _vaultDetails.collateralAssets;
        uint256[] memory _unusedCollateralAmounts = _vaultDetails.availableCollateralAmounts;
        uint256[] memory _collateralsDecimals = _vaultDetails.collateralsDecimals;

        uint256 collateralsLength = _collateralAssets.length;
        // then we need arrays to use short onToken collateral constraints
        ONtokenInterface short = ONtokenInterface(_vaultDetails.shortONtoken);
        // collateral constraints - is absolute amounts of collateral that can be used to cover corresponding short
        // used to restrict high collaterization with risky assets
        uint256[] memory _shortCollateralConstraints = short.getCollateralConstraints();
        // _shortCollateralsAmounts - amounts of existing collaterization of onToken by every collateral
        uint256[] memory _shortCollateralsAmounts = short.getCollateralsAmounts();
        FPI.FixedPointInt[] memory availableCollateralsValues = new FPI.FixedPointInt[](collateralsLength);
        FPI.FixedPointInt memory availableCollateralTotalValue;

        FPI.FixedPointInt[] memory availableCollateralsAmounts = new FPI.FixedPointInt[](collateralsLength);

        for (uint256 i = 0; i < collateralsLength; i++) {
            if (_unusedCollateralAmounts[i] == 0) {
                availableCollateralsValues[i] = ZERO;
                continue;
            }
            availableCollateralsAmounts[i] = FPI.fromScaledUint(_unusedCollateralAmounts[i], _collateralsDecimals[i]);

            // if this collateral token has constraint
            if (_shortCollateralConstraints[i] > 0) {
                FPI.FixedPointInt memory maxAmount = FPI.fromScaledUint(
                    _shortCollateralConstraints[i].sub(_shortCollateralsAmounts[i]),
                    _collateralsDecimals[i]
                );
                // take min from constraint or this collateral avaialable
                availableCollateralsAmounts[i] = FPI.min(maxAmount, availableCollateralsAmounts[i]);
            }

            // convert amounts to value in strike asset by current price
            availableCollateralsValues[i] = _convertAmountOnLivePrice(
                availableCollateralsAmounts[i],
                _collateralAssets[i],
                _strikeAsset
            );

            availableCollateralTotalValue = availableCollateralTotalValue.add(availableCollateralsValues[i]);
        }

        return (availableCollateralsAmounts, availableCollateralsValues, availableCollateralTotalValue);
    }

    /**
     * @dev returns the strike asset amount of margin required for a put or put spread with the given short onTokens, long onTokens and amounts
     *
     * marginRequired = max( (short amount * short strike) - (long strike * min (short amount, long amount)) , 0 )
     *
     * @return margin requirement denominated in the strike asset
     * @return long amount used to cover short
     */
    function _getPutSpreadMarginRequired(
        uint256 _shortAmount,
        uint256 _longAmount,
        uint256 _shortStrike,
        uint256 _longStrike
    ) internal view returns (FPI.FixedPointInt memory, FPI.FixedPointInt memory) {
        FPI.FixedPointInt memory shortStrikeFPI = FPI.fromScaledUint(_shortStrike, BASE);
        FPI.FixedPointInt memory longStrikeFPI = FPI.fromScaledUint(_longStrike, BASE);
        FPI.FixedPointInt memory shortAmountFPI = FPI.fromScaledUint(_shortAmount, BASE);
        FPI.FixedPointInt memory longAmountFPI = _longAmount != 0 ? FPI.fromScaledUint(_longAmount, BASE) : ZERO;

        FPI.FixedPointInt memory longAmountUsed = longStrikeFPI.isEqual(ZERO)
            ? ZERO
            : FPI.min(shortAmountFPI, longAmountFPI);

        return (
            FPI.max(shortAmountFPI.mul(shortStrikeFPI).sub(longStrikeFPI.mul(longAmountUsed)), ZERO),
            longAmountUsed
        );
    }

    /**
     * @dev returns the underlying asset amount required for a call or call spread with the given short onTokens, long onTokens, and amounts
     *
     *                           (long strike - short strike) * short amount
     * marginRequired =  max( ------------------------------------------------- , max (short amount - long amount, 0) )
     *                                           long strike
     *
     * @dev if long strike = 0, return max( short amount - long amount, 0)
     * @return margin requirement denominated in the underlying asset
     * @return long amount used to cover short
     */
    function _getCallSpreadMarginRequired(
        uint256 _shortAmount,
        uint256 _longAmount,
        uint256 _shortStrike,
        uint256 _longStrike
    ) internal view returns (FPI.FixedPointInt memory, FPI.FixedPointInt memory) {
        FPI.FixedPointInt memory shortStrikeFPI = FPI.fromScaledUint(_shortStrike, BASE);
        FPI.FixedPointInt memory longStrikeFPI = FPI.fromScaledUint(_longStrike, BASE);
        FPI.FixedPointInt memory shortAmountFPI = FPI.fromScaledUint(_shortAmount, BASE);
        FPI.FixedPointInt memory longAmountFPI = FPI.fromScaledUint(_longAmount, BASE);

        // max (short amount - long amount , 0)
        if (_longStrike == 0 || _longAmount == 0) {
            return (shortAmountFPI, ZERO);
        }

        /**
         *             (long strike - short strike) * short amount
         * calculate  ----------------------------------------------
         *                             long strike
         */
        FPI.FixedPointInt memory firstPart = longStrikeFPI.sub(shortStrikeFPI).mul(shortAmountFPI).div(longStrikeFPI);

        /**
         * calculate max ( short amount - long amount , 0)
         */
        FPI.FixedPointInt memory secondPart = FPI.max(shortAmountFPI.sub(longAmountFPI), ZERO);

        FPI.FixedPointInt memory longAmountUsed = longStrikeFPI.isEqual(ZERO)
            ? ZERO
            : FPI.min(shortAmountFPI, longAmountFPI);

        return (FPI.max(firstPart, secondPart), longAmountUsed);
    }

    /**
     * @dev calculates current onToken's amount collaterization with it's collaterals
     * @return collateralsAmountsUsed - is amounts of each collateral used to cover onToken
     * @return collateralsValuesUsed - is value (in strike asset) of each collateral used to cover onToken
     */
    function _calculateONtokenCollaterizationsOfAmount(address _onToken, FPI.FixedPointInt memory _amount)
        internal
        view
        returns (uint256[] memory, uint256[] memory)
    {
        ONTokenDetails memory onTokenDetails = ONTokenDetails(
            new address[](0), // [yvUSDC, cUSDC, ...etc]
            new uint256[](0), // [0, 200, ...etc]
            new uint256[](0), // [0, 200, ...etc]
            new uint256[](0), // [18, 8, 10]
            address(0), // WETH
            address(0), // USDC
            0,
            0,
            false,
            0
        );
        (
            onTokenDetails.collaterals, // yvUSDC
            onTokenDetails.collateralsAmounts,
            onTokenDetails.collateralsValues, // WETH // USDC
            onTokenDetails.collateralsDecimals,
            ,
            ,
            ,
            ,
            ,

        ) = _getONtokenDetails(_onToken);

        // Create "higher" variable in stack same as function argument to prevent stack too deep error when accessing amount
        FPI.FixedPointInt memory amount = _amount;
        uint256[] memory collateralsAmounts = new uint256[](onTokenDetails.collaterals.length);
        uint256[] memory collateralsValues = new uint256[](onTokenDetails.collaterals.length);

        if (amount.isEqual(ZERO)) {
            return (collateralsAmounts, collateralsValues);
        }

        FPI.FixedPointInt memory onTokenTotalCollateralValue = FPI.fromScaledUint(
            uint256ArraySum(onTokenDetails.collateralsValues),
            BASE
        );

        for (uint256 i = 0; i < onTokenDetails.collaterals.length; i++) {
            uint256 collateralDecimals = onTokenDetails.collateralsDecimals[i];
            FPI.FixedPointInt memory collateralValue = FPI.fromScaledUint(onTokenDetails.collateralsValues[i], BASE);
            FPI.FixedPointInt memory collateralRatio = collateralValue.div(onTokenTotalCollateralValue);

            collateralsAmounts[i] = amount
                .mul(FPI.fromScaledUint(onTokenDetails.collateralsAmounts[i], collateralDecimals))
                .mul(collateralRatio)
                .toScaledUint(collateralDecimals, true);

            collateralsValues[i] = collateralValue.mul(collateralRatio).toScaledUint(BASE, true);
        }

        return (collateralsAmounts, collateralsValues);
    }
}