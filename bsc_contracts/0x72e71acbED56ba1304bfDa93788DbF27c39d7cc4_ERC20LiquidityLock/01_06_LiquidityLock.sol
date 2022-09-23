// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ERC20LiquidityLock is Ownable {

    using SafeERC20 for IERC20;
    uint256 public unlockTime = 0;

    constructor(uint256 lockedTime) {
        unlockTime = block.timestamp + lockedTime;
    }

    function claimLockedTokens(address tokenAddress) public onlyOwner {

        IERC20 tokenToTransfer = IERC20(tokenAddress);

        require(block.timestamp > unlockTime, "Funds are still locked");
        require(tokenToTransfer.balanceOf(address(this)) > 0, "Contract holds none of this tokens");

        tokenToTransfer.safeTransfer(msg.sender, tokenToTransfer.balanceOf(address(this)));
    }
}