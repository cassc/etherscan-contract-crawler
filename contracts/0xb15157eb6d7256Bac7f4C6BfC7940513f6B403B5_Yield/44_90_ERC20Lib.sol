//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library ERC20Lib {
    error ApproveFailed(IERC20 token);

    function checkedInfiniteApprove(IERC20 token, address spender) internal {
        checkedApprove(token, spender, type(uint256).max);
    }

    /// @notice this fails for improperly implemented ERC20 that don't return anything on .approve(),
    // for a full blown check, use OZ SafeERC20
    function checkedApprove(IERC20 token, address spender, uint256 amount) internal {
        bool success = token.approve(spender, amount);
        if (!success) {
            revert ApproveFailed(token);
        }
    }
}