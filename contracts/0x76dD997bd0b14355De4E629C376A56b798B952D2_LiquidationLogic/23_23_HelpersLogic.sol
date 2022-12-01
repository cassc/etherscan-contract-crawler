// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library HelpersLogic {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function approveMax(address asset, address spender, uint256 minAmount) internal {
        uint256 currAllowance = IERC20Upgradeable(asset).allowance(address(this), spender);

        if (currAllowance < minAmount) {
            IERC20Upgradeable(asset).safeApprove(spender, 0);
            IERC20Upgradeable(asset).safeApprove(spender, type(uint256).max);
        }
    }
}