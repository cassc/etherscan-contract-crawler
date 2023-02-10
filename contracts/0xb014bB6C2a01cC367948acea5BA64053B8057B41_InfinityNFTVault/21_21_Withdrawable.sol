// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

abstract contract Withdrawable {
    using SafeERC20 for ERC20;

    modifier protectedWithdrawal() virtual;

    receive() external payable {}

    function withdrawToken(address to, address token_) external protectedWithdrawal {
        ERC20 tokenToWithdraw = ERC20(token_);
        tokenToWithdraw.safeTransfer(to, tokenToWithdraw.balanceOf(address(this)));
    }

    function withdrawETH(address payable to) external protectedWithdrawal {
        to.transfer(address(this).balance);
    }
}