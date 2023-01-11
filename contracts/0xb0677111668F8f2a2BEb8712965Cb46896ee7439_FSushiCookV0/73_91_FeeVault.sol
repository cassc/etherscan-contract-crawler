// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IERC20Receiver.sol";

contract FeeVault is IERC20Receiver {
    using SafeERC20 for IERC20;

    mapping(address => uint256) claimableAmount;

    function onReceiveERC20(
        address token,
        address,
        uint256
    ) external {
        claimableAmount[token] = IERC20(token).balanceOf(address(this));
    }

    function claim(address token) external {
        uint256 amount = claimableAmount[token];
        claimableAmount[token] = 0;

        IERC20(token).safeTransfer(msg.sender, amount);
    }
}