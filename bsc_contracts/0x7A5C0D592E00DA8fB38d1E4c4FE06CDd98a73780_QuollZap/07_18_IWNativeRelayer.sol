// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IWNativeRelayer {
    function withdraw(address _wNative, uint256 _amount) external;
}