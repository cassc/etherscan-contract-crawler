// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import "../interface/IWETH.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library CurrencyTransferLib {
    using SafeERC20 for IERC20;

    address public constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            safeTransferNativeToken(_to, _amount);
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    function transferCurrencyWithWrapper(
        address _currency,
        address _from,
        address _to,
        uint256 _amount,
        address _nativeTokenWrapper
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            if (_from == address(this)) {
                IWETH(_nativeTokenWrapper).withdraw(_amount);
                safeTransferNativeTokenWithWrapper(
                    _to,
                    _amount,
                    _nativeTokenWrapper
                );
            } else if (_to == address(this)) {
                require(_amount == msg.value, "msg.value != amount");
                IWETH(_nativeTokenWrapper).deposit{value: _amount}();
            } else {
                safeTransferNativeTokenWithWrapper(
                    _to,
                    _amount,
                    _nativeTokenWrapper
                );
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }

        if (_from == address(this)) {
            IERC20(_currency).safeTransfer(_to, _amount);
        } else {
            IERC20(_currency).safeTransferFrom(_from, _to, _amount);
        }
    }

    function safeTransferNativeToken(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "native token transfer failed");
    }

    function safeTransferNativeTokenWithWrapper(
        address to,
        uint256 value,
        address _nativeTokenWrapper
    ) internal {
        (bool success, ) = to.call{value: value}("");
        if (!success) {
            IWETH(_nativeTokenWrapper).deposit{value: value}();
            IERC20(_nativeTokenWrapper).safeTransfer(to, value);
        }
    }
}