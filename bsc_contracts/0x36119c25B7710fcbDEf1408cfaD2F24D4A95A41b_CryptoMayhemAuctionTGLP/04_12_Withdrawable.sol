// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Withdrawable is Ownable {
    using SafeERC20 for IERC20;

    receive() external payable {}

    function withdrawToken(address to, address token_) external onlyOwner {
        IERC20 tokenToWithdraw = IERC20(token_);
        tokenToWithdraw.safeTransfer(to, tokenToWithdraw.balanceOf(address(this)));
    }

    function withdrawETH(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }
}