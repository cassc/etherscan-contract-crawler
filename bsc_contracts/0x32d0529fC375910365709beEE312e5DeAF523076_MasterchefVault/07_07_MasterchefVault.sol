// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MasterchefVault is Ownable {
    using SafeERC20 for IERC20;

    function safeTransfer(
        IERC20 from,
        address to,
        uint amount
    ) external onlyOwner {
        from.safeTransfer(to, amount);
    }

    function getTokenAddressBalance(
        address token
    ) external view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function getTokenBalance(IERC20 token) external view returns (uint) {
        return token.balanceOf(address(this));
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}