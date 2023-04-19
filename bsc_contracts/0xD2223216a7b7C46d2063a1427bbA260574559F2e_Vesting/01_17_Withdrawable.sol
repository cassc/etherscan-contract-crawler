// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Withdrawable {
    using SafeERC20 for IERC20;

    modifier protectedWithdrawal() virtual;

    receive() external payable {}

    function withdrawToken(address to, address token_) external protectedWithdrawal {
        IERC20 tokenToWithdraw = IERC20(token_);
        tokenToWithdraw.safeTransfer(to, tokenToWithdraw.balanceOf(address(this)));
    }

    function withdrawETH(address payable to) external protectedWithdrawal {
        require(to != address(0), "Withdrawable: withdraw to the zero address");

        to.transfer(address(this).balance);
    }
}