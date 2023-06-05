// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ReturnAnyERC20Token {
    using SafeERC20 for IERC20;
    // return any token
    function _returnAnyToken(address tokenAddress, address to, uint256 amount) internal{
        require(tokenAddress != address(0), "Can not return zero address");
        require(to != address(0), "Can not return to zero address");
        require(amount > 0, "Can not return zero amount");

        IERC20(tokenAddress).transfer(to, amount);
    }
}