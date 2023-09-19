// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IDABotComponent.sol";



/**
@dev An common interface of a DABot module.
 */
interface IDABotModule is IDABotComponent {
    event ModuleRegistered(string name, bytes32 moduleId, address indexed moduleAddress);
    
    function onRegister(address moduleAddress) external;
    function onInitialize(bytes calldata data) external;
}