/*
TokenUtilsInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Token utilities info
 *
 * @notice this library implements utility methods for token handling,
 * dynamic balance accounting, and fee processing.
 *
 * this is a modified version to be used by info libraries.
 */
library TokenUtilsInfo {
    uint256 constant INITIAL_SHARES_PER_TOKEN = 1e6;
    uint256 constant FLOOR_SHARES_PER_TOKEN = 1e3;

    /**
     * @notice get token shares from amount
     * @param token erc20 token interface
     * @param module address of module
     * @param total current total shares
     * @param amount balance of tokens
     */
    function getShares(
        IERC20 token,
        address module,
        uint256 total,
        uint256 amount
    ) internal view returns (uint256) {
        if (total == 0) return 0;
        uint256 balance = token.balanceOf(module);
        if (total < balance * FLOOR_SHARES_PER_TOKEN)
            return amount * FLOOR_SHARES_PER_TOKEN;
        return (total * amount) / balance;
    }

    /**
     * @notice get token amount from shares
     * @param token erc20 token interface
     * @param module address of module
     * @param total current total shares
     * @param shares balance of shares
     */
    function getAmount(
        IERC20 token,
        address module,
        uint256 total,
        uint256 shares
    ) internal view returns (uint256) {
        if (total == 0) return 0;
        uint256 balance = token.balanceOf(module);
        if (total < balance * FLOOR_SHARES_PER_TOKEN)
            return shares / FLOOR_SHARES_PER_TOKEN;
        return (balance * shares) / total;
    }
}