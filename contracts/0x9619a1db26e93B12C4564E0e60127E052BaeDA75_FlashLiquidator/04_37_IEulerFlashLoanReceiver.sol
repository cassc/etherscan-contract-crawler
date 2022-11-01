// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.0;

interface IEulerFlashLoanReceiver {
    function onFlashLoan(bytes memory data) external;
}