// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {IWETH} from "src/interfaces/IWETH.sol";
import {ILido} from "src/interfaces/ILido.sol";
import {Constants} from "src/libraries/Constants.sol";
import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ITokenTransferProxy} from "src/interfaces/ITokenTransferProxy.sol";

/// @title TokenUtils
/// @notice Utility functions for tokens.
library TokenUtils {
    using SafeTransferLib for ERC20;

    function _depositSTETH(uint256 _amount) internal {
        ILido(Constants._stETH).submit{value: _amount}(address(this));
    }

    function _depositWETH(uint256 _amount) internal {
        IWETH(Constants._WETH).deposit{value: _amount}();
    }

    /// @notice Approves a spender to spend an ERC20 token if not already approved.
    /// @param token The ERC20 token to approve.
    /// @param spender The address to approve.
    function _approve(address token, address spender) internal {
        if (spender == address(0)) {
            return;
        }
        if (ERC20(token).allowance(address(this), spender) == 0) {
            ERC20(token).safeApprove(spender, type(uint256).max);
        }
    }

    /// @notice Transfer funds from the sender to the contract, if needed.
    /// @param amountIn The amount of funds to transfer.
    /// @param token The token to transfer.
    function _amountIn(uint256 amountIn, address token) internal returns (uint256) {
        if (amountIn == Constants.CONTRACT_BALANCE) {
            if (token == Constants._ETH) {
                return address(this).balance;
            }
            return ERC20(token).balanceOf(address(this));
        } else if (token == Constants._ETH) {
            return msg.value;
        } else {
            ITokenTransferProxy(Constants._LIQUID_TRANSFER_PROXY).transferFrom(
                token, msg.sender, address(this), amountIn
            );
        }
        return amountIn;
    }

    /// @notice Transfer utils from the contract to the recipient, if needed.
    /// @param _token The token to transfer.
    /// @param _to The recipient address.
    /// @param _amount The amount of funds to transfer.
    function _transfer(address _token, address _to, uint256 _amount) internal returns (uint256) {
        if (_amount == type(uint256).max) {
            _amount = _balanceInOf(_token, address(this));
        }

        if (_to != address(0) && _to != address(this) && _amount != 0) {
            if (_token != Constants._ETH) {
                ERC20(_token).safeTransfer(_to, _amount);
            } else {
                SafeTransferLib.safeTransferETH(_to, _amount);
            }

            return _amount;
        }

        return 0;
    }

    /// @notice Get the balance of an account.
    /// @param _token The token to get the balance of.
    /// @param _acc The account to get the balance of.
    function _balanceInOf(address _token, address _acc) internal view returns (uint256) {
        if (_token == Constants._ETH) {
            return _acc.balance;
        } else {
            return ERC20(_token).balanceOf(_acc);
        }
    }
}