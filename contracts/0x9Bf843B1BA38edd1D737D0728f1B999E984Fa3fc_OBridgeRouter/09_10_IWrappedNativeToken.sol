// contracts/interfaces/IOBridgeERC20.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWrappedNativeToken {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}