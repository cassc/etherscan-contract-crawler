/*
TokenUtils

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Token utilities
 *
 * @notice this library implements utility methods for token handling,
 * dynamic balance accounting, and fee processing
 */
library TokenUtils {
    using SafeERC20 for IERC20;

    event Fee(address indexed receiver, address indexed token, uint256 amount); // redefinition

    uint256 constant INITIAL_SHARES_PER_TOKEN = 1e6;
    uint256 constant FLOOR_SHARES_PER_TOKEN = 1e3;

    /**
     * @notice get token shares from amount
     * @param token erc20 token interface
     * @param total current total shares
     * @param amount balance of tokens
     */
    function getShares(
        IERC20 token,
        uint256 total,
        uint256 amount
    ) internal view returns (uint256) {
        if (total == 0) return 0;
        uint256 balance = token.balanceOf(address(this));
        if (total < balance * FLOOR_SHARES_PER_TOKEN)
            return amount * FLOOR_SHARES_PER_TOKEN;
        return (total * amount) / balance;
    }

    /**
     * @notice get token amount from shares
     * @param token erc20 token interface
     * @param total current total shares
     * @param shares balance of shares
     */
    function getAmount(
        IERC20 token,
        uint256 total,
        uint256 shares
    ) internal view returns (uint256) {
        if (total == 0) return 0;
        uint256 balance = token.balanceOf(address(this));
        if (total < balance * FLOOR_SHARES_PER_TOKEN)
            return shares / FLOOR_SHARES_PER_TOKEN;
        return (balance * shares) / total;
    }

    /**
     * @notice transfer tokens from sender into contract and convert to shares
     * for internal accounting
     * @param token erc20 token interface
     * @param total current total shares
     * @param sender token sender
     * @param amount number of tokens to be sent
     */
    function receiveAmount(
        IERC20 token,
        uint256 total,
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        // note: we assume amount > 0 has already been validated

        //  transfer
        uint256 balance = token.balanceOf(address(this));
        token.safeTransferFrom(sender, address(this), amount);
        uint256 actual = token.balanceOf(address(this)) - balance;
        require(amount >= actual);

        // mint shares at current rate
        uint256 minted;
        if (total == 0) {
            minted = actual * INITIAL_SHARES_PER_TOKEN;
        } else if (total < balance * FLOOR_SHARES_PER_TOKEN) {
            minted = actual * FLOOR_SHARES_PER_TOKEN;
        } else {
            minted = (total * actual) / balance;
        }
        require(minted > 0);
        return minted;
    }

    /**
     * @notice transfer tokens from sender into contract, process protocol fee,
     * and convert to shares for internal accounting
     * @param token erc20 token interface
     * @param total current total shares
     * @param sender token sender
     * @param amount number of tokens to be sent
     * @param feeReceiver address to receive fee
     * @param feeRate portion of amount to take as fee in 18 decimals
     */
    function receiveWithFee(
        IERC20 token,
        uint256 total,
        address sender,
        uint256 amount,
        address feeReceiver,
        uint256 feeRate
    ) internal returns (uint256) {
        // note: we assume amount > 0 has already been validated

        // check initial token balance
        uint256 balance = token.balanceOf(address(this));

        // process fee
        uint256 fee;
        if (feeReceiver != address(0) && feeRate > 0 && feeRate < 1e18) {
            fee = (amount * feeRate) / 1e18;
            token.safeTransferFrom(sender, feeReceiver, fee);
            emit Fee(feeReceiver, address(token), fee);
        }

        // do transfer
        token.safeTransferFrom(sender, address(this), amount - fee);
        uint256 actual = token.balanceOf(address(this)) - balance;
        require(amount >= actual);

        // mint shares at current rate
        uint256 minted;
        if (total == 0) {
            minted = actual * INITIAL_SHARES_PER_TOKEN;
        } else if (total < balance * FLOOR_SHARES_PER_TOKEN) {
            minted = actual * FLOOR_SHARES_PER_TOKEN;
        } else {
            minted = (total * actual) / balance;
        }
        require(minted > 0);
        return minted;
    }
}