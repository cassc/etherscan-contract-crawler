// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library SafeERC20Transfer {
    using SafeERC20 for IERC20;

    function safeERC20Transfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount != 0) {
            IERC20(token).safeTransferFrom(from, to, amount);
        }
    }
}