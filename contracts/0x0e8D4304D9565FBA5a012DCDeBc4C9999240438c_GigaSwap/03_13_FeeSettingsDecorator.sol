// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './IFeeSettings.sol';

contract FeeSettingsDecorator is IFeeSettings {
    IFeeSettings public immutable feeSettings;

    constructor(address feeSettingsAddress) {
        feeSettings = IFeeSettings(feeSettingsAddress);
    }

    function feeAddress() external virtual returns (address) {
        return feeSettings.feeAddress();
    }

    function feePercent() external virtual returns (uint256) {
        return feeSettings.feePercent();
    }

    function feeDecimals() external view returns(uint256){
        return feeSettings.feeDecimals();
    }

    function feeEth() external virtual returns (uint256) {
        return feeSettings.feeEth();
    }
}