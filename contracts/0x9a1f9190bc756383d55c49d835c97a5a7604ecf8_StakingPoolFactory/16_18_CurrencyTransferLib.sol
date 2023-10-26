// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library CurrencyTransferLib {
       using SafeERC20 for IERC20;

    address public constant NATIVE_TOKEN =
        0x0000000000000000000000000000000000000000;

    function transferCurrency(
        address currency,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (currency == NATIVE_TOKEN) {
            safeTransferNativeToken(to, amount);
        } else {
            safeTransferERC20(currency, from, to, amount);
        }
    }

    function safeTransferNativeToken(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success);
    }

    function safeTransferERC20(
        address currency,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from == to) {
            return;
        }

        if (from == address(this)) {
            IERC20(currency).safeTransfer(to, amount);
        } else {
            IERC20(currency).safeTransferFrom(from, to, amount);
        }
    }
}