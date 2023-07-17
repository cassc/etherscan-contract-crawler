// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Authorizable {

    mapping(address => bool) public authorized;

    // solhint-disable func-visibility
    constructor() {
        authorized[msg.sender] = true;
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Not authorized");
        _;
    }

    function addAuthorized(address _address) external onlyAuthorized {
        require(_address != address(0));
        authorized[_address] = true;
    }

    function removeAuthorized(address _address) external onlyAuthorized {
        require(_address != address(0));
        require(_address != msg.sender, "Can't remove your own address");
        authorized[_address] = false;
    }

}