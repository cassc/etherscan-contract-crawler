// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
    @title Currency
    @author iMe Lab
    @notice Library for working with arbitrary crypto currencies
 */
library Currency {
    error CurrencyTransferFailed();

    address internal constant NATIVE = address(0);

    function balanceOf(
        address currency,
        address account
    ) internal view returns (uint256) {
        if (currency == NATIVE) return account.balance;

        return IERC20(currency).balanceOf(account);
    }

    function transfer(
        address currency,
        address account,
        uint256 amount
    ) internal {
        _safe(_transfer(currency, account, amount));
    }

    function take(
        address currency,
        address from,
        address to,
        uint256 amount
    ) internal {
        _safe(_take(currency, from, to, amount));
    }

    function _transfer(
        address currency,
        address account,
        uint256 amount
    ) private returns (bool) {
        if (currency == NATIVE) return payable(account).send(amount);

        return IERC20(currency).transfer(account, amount);
    }

    function _take(
        address currency,
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        if (currency == NATIVE) {
            // We expect to receive `amount` from `spender` via payable
            return payable(to).send(amount);
        }

        return IERC20(currency).transferFrom(from, to, amount);
    }

    function _safe(bool transferred) private pure {
        if (!transferred) revert CurrencyTransferFailed();
    }
}