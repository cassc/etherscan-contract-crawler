// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

library Util {
    /// @dev Return the decimals of an ERC20 token (if the implementations offers it)
    /// @param _token (IERC20) the ERC20 token
    /// @return  (uint8) the decimals
    function getERC20Decimals(IERC20Upgradeable _token) internal view returns (uint8) {
        return IERC20MetadataUpgradeable(address(_token)).decimals();
    }

    /// @dev Converts a number from one decimal precision to the other
    /// @param _number (uint256) the number
    /// @param _currentDecimals (uint256) the current decimals of the number
    /// @param _targetDecimals (uint256) the desired decimals for the number
    /// @return  (uint256) the number with _targetDecimals decimals
    function convertDecimals(uint256 _number, uint256 _currentDecimals, uint256 _targetDecimals) internal pure returns (uint256) {
        uint256 diffDecimals;

        uint256 amountCorrected = _number;

        if (_targetDecimals < _currentDecimals) {
            diffDecimals = _currentDecimals - _targetDecimals;
            amountCorrected = _number / (uint256(10) ** diffDecimals);
        } else if (_targetDecimals > _currentDecimals) {
            diffDecimals = _targetDecimals - _currentDecimals;
            amountCorrected = _number * (uint256(10) ** diffDecimals);
        }

        return (amountCorrected);
    }

    /// @dev Converts a number from one decimal precision to the other based on two ERC20 Tokens
    /// @param _number (uint256) the number
    /// @param _sourceToken (address) the source ERC20 Token
    /// @param _targetToken (address) the target ERC20 Token
    /// @return  (uint256) the number with _targetDecimals decimals
    function convertDecimalsERC20(uint256 _number, IERC20Upgradeable _sourceToken, IERC20Upgradeable _targetToken) internal view returns (uint256) {
        return convertDecimals(_number, getERC20Decimals(_sourceToken), getERC20Decimals(_targetToken));
    }

    function removeValueFromArray(IERC20Upgradeable value, IERC20Upgradeable[] storage array) internal {
        bool shift = false;
        uint256 i = 0;
        while (i < array.length - 1) {
            if (array[i] == value) shift = true;
            if (shift) {
                array[i] = array[i + 1];
            }
            i++;
        }
        array.pop();
    }
}