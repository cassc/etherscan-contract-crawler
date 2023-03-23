// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IWrappedNativeToken {
    function deposit() external payable;

    function withdraw(uint256) external;
}