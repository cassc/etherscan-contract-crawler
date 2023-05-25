// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Withdrawable is Ownable, ReentrancyGuard {
    error WithdrawFailed();

    event Withdraw(address account, uint256 amount);

    function withdrawAll() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        emit Withdraw(_msgSender(), balance);
        (bool success, ) = _msgSender().call{value: balance}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }
}