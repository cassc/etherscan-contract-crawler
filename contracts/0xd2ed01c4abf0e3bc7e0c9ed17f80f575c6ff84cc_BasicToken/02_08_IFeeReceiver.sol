// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeReceiver {
    function processFee(bytes32 serviceId) external payable;
}