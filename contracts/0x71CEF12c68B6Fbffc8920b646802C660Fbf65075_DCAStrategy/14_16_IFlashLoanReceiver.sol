pragma solidity ^0.8.19;

//SPDX-License-Identifier: MIT

interface IFlashLoanReceiver {
    function executeOperation(address token, uint amount, uint fee, bytes calldata params) external returns (bool);
}