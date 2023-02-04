// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

contract Controllable is Context {
    mapping(address => bool) public controllers;

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);

    modifier onlyController() {
        require(controllers[_msgSender()]);
        _;
    }

    function _addController(address controller_) internal virtual {
        controllers[controller_] = true;
        emit ControllerAdded(controller_);
    }

    function _removeController(address controller_) internal virtual {
        controllers[controller_] = false;
        emit ControllerRemoved(controller_);
    }
}