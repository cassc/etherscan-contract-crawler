// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.0;

interface IEulerDToken {
    function flashLoan(uint amount, bytes calldata data) external;
}