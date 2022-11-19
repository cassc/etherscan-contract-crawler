// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IForeignBridge {
    function relayTokens(address token, address _receiver, uint256 _value) external;
    function relayTokensAndCall(address token, address _receiver, uint256 _value, bytes memory _data) external;
}