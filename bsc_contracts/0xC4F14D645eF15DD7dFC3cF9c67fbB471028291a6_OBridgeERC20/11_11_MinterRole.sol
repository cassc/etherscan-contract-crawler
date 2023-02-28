// contracts/utils/MinterRole.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MinterRole is Ownable {
    mapping(address => bool) public isMinter;

    modifier onlyMinter() {
        require(isMinter[msg.sender], "OBridgeERC20: FORBIDDEN");
        _;
    }

    constructor() {
        isMinter[msg.sender] = true;
    }

    function addMinter(address _minter) public onlyOwner {
        require(_minter != address(0), "OBridgeERC20: Minter address can't be zero.");
        isMinter[_minter] = true;
    }

    function removeMinter(address _minter) public onlyOwner {
        require(isMinter[_minter], "OBridgeERC20: The address is not minter.");
        isMinter[_minter] = false;
    }
}