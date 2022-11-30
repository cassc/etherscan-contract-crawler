// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenHelper {
    struct AccountBalance {
        address account;
        address token;
        uint256 balance;
    }

    function allowances(
        address account,
        address spender,
        address[] memory tokens
    ) external view returns (uint256[] memory) {
        uint256[] memory accountAllowances = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            accountAllowances[i] = IERC20(tokens[i]).allowance(
                account,
                spender
            );
        }

        return accountAllowances;
    }

    /**
     * @dev Check the token balances of a wallet for multiple tokens.
     * Pass 0x0 as a "token" address to get ETH balance.
     *
     * Possible error throws:
     *  - extremely large arrays for user and or tokens (gas cost too high)
     *
     * Returns a one-dimensional that's user.length * tokens.length long. The
     * array is ordered by all of the 0th accounts token balances, then the 1th
     * user, and so on.
     */
    function balances(
        address[] memory accounts,
        address[] memory tokens
    ) external view returns (uint256[] memory) {
        uint256[] memory accountBalances = new uint256[](
            tokens.length * accounts.length
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 addrIdx = j + tokens.length * i;
                if (tokens[j] != address(0x0)) {
                    accountBalances[addrIdx] = IERC20(tokens[j]).balanceOf(
                        accounts[i]
                    );
                } else {
                    accountBalances[addrIdx] = accounts[i].balance; // ETH balance
                }
            }
        }

        return accountBalances;
    }

    /**
     * @dev Check the token balances of a wallet for multiple tokens.
     * Pass 0x0 as a "token" address to get ETH balance.
     *
     * Possible error throws:
     *  - extremely large arrays for user and or tokens (gas cost too high)
     *
     * Returns a one-dimensional array that's user.length * tokens.length long. The
     * array is ordered by all of the 0th accounts token balances, then the 1th
     * user, and so on.
     */
    function balancesStruct(
        address[] memory accounts,
        address[] memory tokens
    ) external view returns (AccountBalance[] memory) {
        AccountBalance[] memory accountBalances = new AccountBalance[](
            tokens.length * accounts.length
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 addrIdx = j + tokens.length * i;
                if (tokens[j] != address(0x0)) {
                    accountBalances[addrIdx] = AccountBalance({
                        account: accounts[i],
                        token: tokens[j],
                        balance: IERC20(tokens[j]).balanceOf(accounts[i])
                    });
                } else {
                    accountBalances[addrIdx] = AccountBalance({
                        account: accounts[i],
                        token: tokens[j],
                        balance: accounts[i].balance
                    });
                }
            }
        }

        return accountBalances;
    }
}