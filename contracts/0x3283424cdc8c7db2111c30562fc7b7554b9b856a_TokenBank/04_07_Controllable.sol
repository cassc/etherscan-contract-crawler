// SPDX-License-Identifier: CC0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

//Simple way of allowing authorized controllers to perform privileged functions
contract Controllable is Ownable {

    mapping(address => bool) controllers; //authorized addresses

    modifier onlyControllers() {
        require(controllers[msg.sender], "Controllable: Authorized controllers only.");
        _;
    }

    function addController(address newController) external onlyOwner {
        controllers[newController] = true;
    }

    function addControllers(address[] calldata newControllers) external onlyOwner {
        for (uint i=0; i < newControllers.length; i++) {
            controllers[newControllers[i]] = true;
        }
    }

    function removeController(address toDelete) external onlyOwner {
        controllers[toDelete] = false; //same as del
    }

}