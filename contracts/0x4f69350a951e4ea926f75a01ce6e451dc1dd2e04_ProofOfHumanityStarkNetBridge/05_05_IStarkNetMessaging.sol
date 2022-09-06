// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IStarkNetMessaging {
    
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);
}