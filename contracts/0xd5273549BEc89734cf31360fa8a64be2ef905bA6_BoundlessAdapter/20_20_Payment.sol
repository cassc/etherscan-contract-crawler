//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

address constant FEE_CURRENCY = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

abstract contract Payment is Context {
    using SafeERC20 for IERC20;

    function acceptPayment(address token, uint256 amount) internal {
        if (token == FEE_CURRENCY || token == address(0x0)) {
            require(msg.value == amount, "Payment: insufficient msg.value");
        } else {
            IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);
        }
    }

    function payToken(
        address to,
        address token,
        uint256 amount
    ) internal {
        if (token == FEE_CURRENCY || token == address(0x0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }
}