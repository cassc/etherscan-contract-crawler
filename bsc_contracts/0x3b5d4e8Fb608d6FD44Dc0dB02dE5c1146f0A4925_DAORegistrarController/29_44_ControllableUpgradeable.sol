//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract ControllableUpgradeable is OwnableUpgradeable {
    mapping(address=>bool) public controllers;

    event ControllerChanged(address indexed controller, bool active);

    function __Controllable_init() internal onlyInitializing {
        __Ownable_init();
    }

    function setController(address controller, bool active) public virtual onlyOwner {
        controllers[controller] = active;
        emit ControllerChanged(controller, active);
    }

    modifier onlyController() {
        require(controllers[msg.sender], "Controllable: Caller is not a controller");
        _;
    }
}