// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./CheezburgerStructs.sol";
import "./CheezburgerConstants.sol";

abstract contract CheezburgerSanitizer is CheezburgerStructs {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error RouterUndefined();
    error NameTooShort(uint256 length, uint256 minLength);
    error NameTooLong(uint256 length, uint256 maxLength);
    error SymbolTooShort(uint256 length, uint256 minLength);
    error SymbolTooLong(uint256 length, uint256 maxLength);
    error WebsiteUrlTooLong(uint256 length, uint256 maxLength);
    error SocialUrlTooLong(uint256 length, uint256 maxLength);
    error SupplyTooLow(uint256 supply);
    error SupplyTooLarge(uint256 supply);
    error InvalidThreshold(uint256 threshold);
    error FeeDurationTooShort(uint256 duration);
    error FeeDurationTooLong(uint256 duration);
    error FeeStartTooLow(uint256 start);
    error FeeStartTooHigh(uint256 start, uint256 max);
    error FeeEndTooHigh(uint256 end, uint256 max);
    error FeeEndExceedsStart(uint256 end, uint256 start);
    error MaxWalletStartTooLow(uint256 start);
    error MaxWalletEndTooLow(uint256 end, uint256 min);
    error MaxWalletEndTooHigh(uint256 end, uint256 max);
    error MaxWalletDurationTooShort(uint256 duration);
    error MaxWalletDurationTooLong(uint256 duration, uint256 maxDuration);
    error TooManyFeeAddresses(uint256 numAddresses);
    error TooFewFeeAddresses(uint256 numAddresses);
    error OverflowFeePercentages(uint8 totalFeePercent);
    error InvalidFeePercentagesLength(
        uint256 percentagesLength,
        uint256 addressesLength
    );
    error FactoryCannotReceiveFees();
    error ReferralCannotBeFactory();
    error ReferralFeeExceeded();
    error ReferralFeeCannotBeZero();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function validateTokenSettings(
        address _router,
        TokenCustomization memory _customization
    ) internal pure {
        if (_router == address(0)) {
            revert RouterUndefined();
        }

        if (
            bytes(_customization.name).length <
            CheezburgerConstants.MIN_NAME_LENGTH
        ) {
            revert NameTooShort(
                bytes(_customization.name).length,
                CheezburgerConstants.MIN_NAME_LENGTH
            );
        }

        if (
            bytes(_customization.name).length >
            CheezburgerConstants.MAX_NAME_LENGTH
        ) {
            revert NameTooLong(
                bytes(_customization.name).length,
                CheezburgerConstants.MAX_NAME_LENGTH
            );
        }

        if (
            bytes(_customization.symbol).length <
            CheezburgerConstants.MIN_SYMBOL_LENGTH
        ) {
            revert SymbolTooShort(
                bytes(_customization.symbol).length,
                CheezburgerConstants.MIN_SYMBOL_LENGTH
            );
        }

        if (
            bytes(_customization.symbol).length >
            CheezburgerConstants.MAX_SYMBOL_LENGTH
        ) {
            revert SymbolTooLong(
                bytes(_customization.symbol).length,
                CheezburgerConstants.MAX_SYMBOL_LENGTH
            );
        }

        if (
            bytes(_customization.website).length >
            CheezburgerConstants.MAX_URL_LENGTH
        ) {
            revert WebsiteUrlTooLong(
                bytes(_customization.website).length,
                CheezburgerConstants.MAX_URL_LENGTH
            );
        }

        if (
            bytes(_customization.social).length >
            CheezburgerConstants.MAX_URL_LENGTH
        ) {
            revert SocialUrlTooLong(
                bytes(_customization.social).length,
                CheezburgerConstants.MAX_URL_LENGTH
            );
        }

        if (_customization.supply < 1) {
            revert SupplyTooLow(_customization.supply);
        }

        if (_customization.supply > CheezburgerConstants.SAFE_TOKEN_SUPPLY) {
            revert SupplyTooLarge(_customization.supply);
        }
    }

    function validateWalletSettings(
        DynamicSettings memory _wallet
    ) internal pure {
        if (_wallet.percentStart < 100) {
            revert MaxWalletStartTooLow(_wallet.percentStart);
        }

        if (_wallet.percentEnd < CheezburgerConstants.WALLET_MIN_PERCENT_END) {
            revert MaxWalletEndTooLow(
                _wallet.percentEnd,
                CheezburgerConstants.WALLET_MIN_PERCENT_END
            );
        }

        if (_wallet.percentEnd > CheezburgerConstants.WALLET_MAX_PERCENT_END) {
            revert MaxWalletEndTooHigh(
                _wallet.percentEnd,
                CheezburgerConstants.WALLET_MAX_PERCENT_END
            );
        }

        if (_wallet.duration < CheezburgerConstants.WALLET_DURATION_MIN) {
            revert MaxWalletDurationTooShort(_wallet.duration);
        }

        if (_wallet.duration > CheezburgerConstants.WALLET_DURATION_CAP) {
            revert MaxWalletDurationTooLong(
                _wallet.duration,
                CheezburgerConstants.WALLET_DURATION_CAP
            );
        }
    }

    function validateReferralSettings(
        ReferralSettings memory _referral,
        address _factory
    ) internal pure {
        if (_referral.feeReceiver != address(0)) {
            if (_referral.feeReceiver == _factory) {
                revert ReferralCannotBeFactory();
            }
            if (_referral.feePercentage <= 0) {
                revert ReferralFeeCannotBeZero();
            }
            if (_referral.feePercentage > CheezburgerConstants.MAX_LP_FEE) {
                revert ReferralFeeExceeded();
            }
        }
    }

    function validateFeeSettings(DynamicSettings memory _fee) internal pure {
        if (_fee.duration < CheezburgerConstants.FEE_DURATION_MIN) {
            revert FeeDurationTooShort(_fee.duration);
        }

        if (_fee.duration > CheezburgerConstants.FEE_DURATION_CAP) {
            revert FeeDurationTooLong(_fee.duration);
        }

        if (_fee.percentStart < CheezburgerConstants.FEE_START_MIN) {
            revert FeeStartTooLow(_fee.percentStart);
        }

        if (_fee.percentStart > CheezburgerConstants.FEE_START_MAX) {
            revert FeeStartTooHigh(
                _fee.percentStart,
                CheezburgerConstants.FEE_START_MAX
            );
        }

        if (_fee.percentEnd > CheezburgerConstants.FEE_END_MAX) {
            revert FeeEndTooHigh(
                _fee.percentEnd,
                CheezburgerConstants.FEE_END_MAX
            );
        }

        if (_fee.percentEnd > _fee.percentStart) {
            revert FeeEndExceedsStart(_fee.percentEnd, _fee.percentStart);
        }
    }

    function validateLiquiditySettings(
        LiquiditySettings memory _fees,
        address _factory
    ) internal pure {
        if (
            _fees.feeThresholdPercent < CheezburgerConstants.THRESHOLD_MIN ||
            _fees.feeThresholdPercent > CheezburgerConstants.THRESHOLD_MAX
        ) {
            revert InvalidThreshold(_fees.feeThresholdPercent);
        }

        if (
            _fees.feeAddresses.length > CheezburgerConstants.FEE_ADDRESSES_MAX
        ) {
            revert TooManyFeeAddresses(_fees.feeAddresses.length);
        }

        if (
            _fees.feeAddresses.length < CheezburgerConstants.FEE_ADDRESSES_MIN
        ) {
            revert TooFewFeeAddresses(_fees.feeAddresses.length);
        }

        // Prevent any of the feeAddresses to be the factory
        for (uint i = 0; i < _fees.feeAddresses.length; i++) {
            if (_fees.feeAddresses[i] == _factory) {
                revert FactoryCannotReceiveFees();
            }
        }

        if (_fees.feePercentages.length != _fees.feeAddresses.length - 1) {
            // If we only have 1 address then we accept [] as feePercentages since 100% goes there
            revert InvalidFeePercentagesLength(
                _fees.feePercentages.length,
                _fees.feeAddresses.length
            );
        }

        if (_fees.feePercentages.length > 1) {
            uint8 totalFeePercent;
            for (uint8 i = 0; i < _fees.feePercentages.length; i++) {
                totalFeePercent += _fees.feePercentages[i];
            }
            if (totalFeePercent > 99) {
                revert OverflowFeePercentages(totalFeePercent);
            }
        }
    }
}