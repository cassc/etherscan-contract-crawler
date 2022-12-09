// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AccessManager is Ownable {
    // Access type
    mapping(address => bool) private accessMap;

    /**
     * @dev Only allow access from specified contracts
     */
    modifier onlyAllowedAddress() {
        require(accessMap[_msgSender()], "Access: sender not allowed");
        _;
    }

    /**
     * @dev Gets if the specified address has access
     * @param _address Address to enable access
     */
    function getAccess(address _address) public view returns (bool) {
        return accessMap[_address];
    }

    /**
     * @dev Enables access to the specified address
     * @param _address Address to enable access
     */
    function enableAccess(address _address) external onlyOwner {
        require(_address != address(0), "Address is empty");
        require(!accessMap[_address], "User already has access");

        accessMap[_address] = true;
    }

    /**
     * @dev Disables access to the specified address
     * @param _address Address to disable access
     */
    function disableAccess(address _address) external onlyOwner {
        require(_address != address(0), "Address is empty");
        require(accessMap[_address], "User already has no access");
        
        accessMap[_address] = false;
    }
}