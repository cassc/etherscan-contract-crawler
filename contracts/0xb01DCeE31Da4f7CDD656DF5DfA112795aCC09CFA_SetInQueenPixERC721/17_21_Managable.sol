// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Managable is Ownable {

    mapping(address => bool) public managers;
    bool public isManagable = true;

    constructor() {

        managers[msg.sender] = true;
    }

    /**
     * Only owner access
     */

    function setManager(address manager, bool enabled) external onlyOwner {

        managers[manager] = enabled;
    }

    function setIn() public onlyOwner {

        isManagable = false;
    }

    /**
     * Only manager access
     */

    modifier onlyManager() {
        
        require(isManagable && managers[msg.sender], "SIMS: no access");
        _;
    }

    function abandon() public onlyManager {

        managers[msg.sender] = false;
    }
}