// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "./Ownable.sol";

/** Controllerable: Dynamic Controller System

    string controllerType is a string version of controllerSlot
    bytes32 controllerSlot is a keccak256(abi.encodePacked("ControllerName"<string>))
        used to store the type of controller type
    address controller is the address of the controller
    bool status is the status of controller (true = is controller, false = is not)

    usage: call isController with string type_ and address of user to receive a boolean
*/

abstract contract Controllerable is Ownable {

    event ControllerSet(string indexed controllerType, bytes32 indexed controllerSlot, 
        address indexed controller, bool status);

    mapping(bytes32 => mapping(address => bool)) internal __controllers;

    function isController(string memory type_, address controller_) public 
    view returns (bool) {
        bytes32 _slot = keccak256(abi.encodePacked(type_));
        return __controllers[_slot][controller_];
    }

    function setController(string calldata type_, address controller_, bool bool_) 
    external onlyOwner {
        bytes32 _slot = keccak256(abi.encodePacked(type_));
        __controllers[_slot][controller_] = bool_;
        emit ControllerSet(type_, _slot, controller_, bool_);
    }
}