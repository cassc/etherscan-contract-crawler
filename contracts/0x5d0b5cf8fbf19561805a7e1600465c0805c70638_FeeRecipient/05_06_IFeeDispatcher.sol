// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface IFeeDispatcher {
    function dispatch(bytes32 _publicKeyRoot) external payable;

    function getWithdrawer(bytes32 _publicKeyRoot) external view returns (address);
}