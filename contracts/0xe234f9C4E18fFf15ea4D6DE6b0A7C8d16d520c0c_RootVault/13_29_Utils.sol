// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @author YLDR <[email protected]>
library Utils {
    using SafeERC20 for IERC20;

    function approveIfZeroAllowance(address asset, address spender) internal {
        if (IERC20(asset).allowance(address(this), spender) == 0) {
            IERC20(asset).safeIncreaseAllowance(spender, type(uint256).max);
        }
    }

    function revokeAllowance(address asset, address spender) internal {
        uint256 allowance = IERC20(asset).allowance(address(this), spender);
        if (allowance > 0) {
            IERC20(asset).safeDecreaseAllowance(spender, allowance);
        }
    }
}