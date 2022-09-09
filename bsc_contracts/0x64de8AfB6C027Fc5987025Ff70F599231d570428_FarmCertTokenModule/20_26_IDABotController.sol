// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DABotCommon.sol"; 

interface IDABotControllerEvent {
    event BotAbandoned(bool value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ModuleHandlerChanged(bytes32 moduleId, address indexed oldModuleAddress, address indexed newModuleAddress);
    event ModuleRegistered(bytes32 moduleId, address indexed moduleAddress, string name, string version);
}

/**
@dev The generic interface of a DABot.
 */
interface IDABotController is IDABotControllerEvent {
    function owner() external view returns(address);
    function abandon(bool value) external;
    function modulesInfo() external view returns(BotModuleInfo[] memory result);
    function governToken() external view returns(address);
    function qualifiedName() external view returns(string memory);
    function metadata() external view returns(BotMetaData memory);
    function setting() external view returns(BotSetting memory);
    function botDetails() view external returns(BotDetail memory);
    function updatePortfolio(address asset, uint maxCap, uint iboCap, uint weight) external;
}