// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

abstract contract AdminControlled is Ownable {
    mapping(address => bool) public adminAddresses;

    /**
     * @dev initializes the contract with admin address list.
     * @param _adminAddresses A list of admin addresses
     */
    constructor(address[] memory _adminAddresses) {
        uint256 len = _adminAddresses.length;
        for (uint256 i = 0; i < len; ) {
            adminAddresses[_adminAddresses[i]] = true;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Throws if called by any address other than the admin address.
     */
    modifier onlyAdminAddress() {
        require(adminAddresses[_msgSender()], "Only admin allowed");
        _;
    }

    /**
     * @notice Adds `adminAddress` to the admin address list.
     * @param adminAddress Admin address should be enabled/disabled
     * @param enable Flag indicating if address should be admin or not
     * @dev Only contract owner can call this function
     */
    function setAdminAddress(address adminAddress, bool enable) external onlyOwner {
        adminAddresses[adminAddress] = enable;
    }
}