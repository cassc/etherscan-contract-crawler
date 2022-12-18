// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StandaloneTreasury is Ownable {
    function allowPoolClaiming(
        IERC20 rewardToken,
        address stakingPool,
        uint256 amount
    ) external onlyOwner {
        if (amount == 0) {
            amount = 100000000000000 ether;
        }
        rewardToken.approve(stakingPool, amount);
    }

    function withdrawToken(address token) external onlyOwner {
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }
}