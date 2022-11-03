// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeTransferWithFeesUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function safeTransferFromWithFees(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal returns (uint256) {
        uint256 balanceBefore = token.balanceOf(to);
        token.safeTransferFrom(from, to, value);
        uint256 balanceAfter = token.balanceOf(to);

        // Overflow check added by Solidity compiler.
        // The result is also only used if it's less than `value`.
        uint256 balanceIncrease = balanceAfter - balanceBefore;

        return MathUpgradeable.min(value, balanceIncrease);
    }
}