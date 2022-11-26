// SPDX-License-Identifier: MIT
// Allowed Addresses by Verdomi

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AllowedAddresses is Ownable {
    mapping(address => bool) private allowedAddresses;

    /**
     * @dev Throws if called by any account that is not allowed.
     */
    modifier onlyAllowedAddresses() {
        require(allowedAddresses[_msgSender()], "AllowedAddresses: caller is not allowed");
        _;
    }

    /**
     * @dev Retruns true if the address is allowed and false if the address is not allowed.
     */
    function isAllowed(address _address) external view returns (bool) {
        return allowedAddresses[_address];
    }

    /**
     * @dev Adds the input address (`_address`) to the allowed list.
     */
    function addAllowed(address _address) external onlyOwner {
        allowedAddresses[_address] = true;
    }

    /**
     * @dev Removes the input address (`_address`) from the allowed list.
     */
    function removeAllowed(address _address) external onlyOwner {
        allowedAddresses[_address] = false;
    }
}