// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

interface ERC677Receiver {
    function onTokenTransfer(address _sender, uint256 _value, bytes calldata _data) external;
}