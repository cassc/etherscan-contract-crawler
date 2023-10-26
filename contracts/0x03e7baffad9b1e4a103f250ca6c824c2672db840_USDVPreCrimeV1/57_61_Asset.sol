// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Governance} from "./Governance.sol";

library Asset {
    using SafeERC20 for IERC20;
    using Governance for Governance.Info;

    struct Info {
        IERC20 token;
        bool registered;
        bool enabled; // to allow minting
        uint usdvToTokenRate;
        // all the following values are in token amount
        uint collateralized;
    }

    error TokenDecimalInvalid(uint provided, uint min);
    error Disabled();
    error AlreadyRegistered();
    error SlippageTooHigh();
    error NotRegistered();

    modifier onlyRegistered(Info storage _self) {
        if (!_self.registered) revert NotRegistered();
        _;
    }

    function initialize(Info storage _self, address _token, uint8 _shareDecimals) internal {
        if (_self.registered) revert AlreadyRegistered();

        // set token
        _self.token = IERC20(_token);
        _self.enabled = true;
        _self.registered = true;

        // set conversion rate
        uint8 tokenDecimals = IERC20Metadata(_token).decimals();
        if (_shareDecimals > tokenDecimals) {
            revert TokenDecimalInvalid(tokenDecimals, _shareDecimals);
        }
        _self.usdvToTokenRate = 10 ** (tokenDecimals - _shareDecimals);
    }

    // @dev if _newFund is true, _from must approve the token transfer
    // @dev if internal mint such as turning yield into collateral, _newFund should be false
    function credit(Info storage _self, address _from, uint64 _usdvAmount, bool _newFund) internal {
        // assert the asset is enabled
        if (!_self.enabled) revert Disabled();

        uint tokenAmount = _usdv2Token(_self, _usdvAmount);
        _self.collateralized += tokenAmount;

        if (_newFund) {
            _self.token.safeTransferFrom(_from, address(this), tokenAmount);
        }
    }

    function redeem(
        Info storage _self,
        Governance.Info storage _govInfo,
        address _receiver,
        uint64 _usdvAmount,
        uint64 _minUsdvAmount
    ) internal onlyRegistered(_self) returns (uint amountAfterFee) {
        uint tokenAmount = _usdv2Token(_self, _usdvAmount);
        _self.collateralized -= tokenAmount;
        // pay redemption fee
        amountAfterFee = _govInfo.payRedemptionFee(_self.token, tokenAmount);
        if (amountAfterFee < _usdv2Token(_self, _minUsdvAmount)) revert SlippageTooHigh();

        // transfer collateral to receiver
        _self.token.safeTransfer(_receiver, amountAfterFee);
    }

    function setEnabled(Info storage _self, bool _enabled) internal onlyRegistered(_self) {
        _self.enabled = _enabled;
    }

    // ========================= View =========================
    /// @return reward in usdv
    function distributable(Info storage _self) internal view returns (uint) {
        uint rebasedFunds = _self.token.balanceOf(address(this)) - _self.collateralized;
        return rebasedFunds / _self.usdvToTokenRate;
    }

    function redeemOutput(
        Info storage _self,
        Governance.Info storage _govInfo,
        uint64 _shares
    ) internal view returns (uint) {
        uint tokenAmount = _usdv2Token(_self, _shares);
        return tokenAmount - _govInfo.getRedemptionFee(tokenAmount);
    }

    // ========================= Internal =========================
    function _usdv2Token(Info storage _self, uint64 _shares) private view returns (uint) {
        return _shares * _self.usdvToTokenRate;
    }
}