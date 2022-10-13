// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITaxes {
    function beforeTransfer(address operator, address from, address to, uint256 amount) external returns(bool success, uint256 amountAdjusted);
}