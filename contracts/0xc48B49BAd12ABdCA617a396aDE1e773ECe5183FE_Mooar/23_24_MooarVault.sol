// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TransferHelper.sol";

contract MooarVault is Ownable {
    function withdraw(address receiver, address token, uint256 amount) external onlyOwner {
        TransferHelper.safeTransfer(token, receiver, amount);
    }
}