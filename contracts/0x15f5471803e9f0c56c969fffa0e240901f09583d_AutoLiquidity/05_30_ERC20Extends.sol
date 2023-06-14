// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/// @title ERC20 extends libraries
/// @notice libraries
library ERC20Extends {

    using SafeERC20 for IERC20;

    /// @notice Safe approve
    /// @dev Avoid errors that occur in some ERC20 token authorization restrictions
    /// @param token Approval token address
    /// @param to Approval address
    /// @param amount Approval amount
    function safeApprove(address token, address to, uint256 amount) internal {
        IERC20 tokenErc20 = IERC20(token);
        uint256 allowance = tokenErc20.allowance(address(this), to);
        if (allowance < amount) {
            if (allowance > 0) {
                tokenErc20.safeApprove(to, 0);
            }
            tokenErc20.safeApprove(to, amount);
        }
    }
}