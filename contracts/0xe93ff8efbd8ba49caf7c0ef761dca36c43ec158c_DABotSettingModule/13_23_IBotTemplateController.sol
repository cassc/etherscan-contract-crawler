// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IBotTemplateController {
    function registerModule(address moduleHandler) external;
    function updateModuleHandler(bytes32 moduleId, address newModuleAddress) external;
    function module(bytes32 moduleId) external view returns(address);
    function moduleOfSelector(bytes32 selector) external view returns(address);
}