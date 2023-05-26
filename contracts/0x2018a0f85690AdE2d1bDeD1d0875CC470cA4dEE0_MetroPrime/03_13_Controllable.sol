// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Controllable is Ownable {

    mapping(address => bool) private controllers;

    function addController(address controller) external onlyOwner {
      controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
      controllers[controller] = false;
    }

    function isController(address account) public view returns (bool) {
        return controllers[account];
    }

    modifier onlyController() {
        require(controllers[_msgSender()], "Controllable: caller is not the controller");
        _;
    }
}