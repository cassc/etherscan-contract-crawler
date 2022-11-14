// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OnlyAuthorized is Ownable{
    mapping(address => bool) private authorized;

    constructor(){
        authorized[msg.sender] = true;
    }

    function isAuthorized(address addr) public view returns (bool) {
        return authorized[addr];
    }

    function authorizeTo(address addr) public onlyOwner {
        require(addr != address(0));
        authorized[addr] = true;
    }

    function removeAuthorization(address addr) public onlyOwner {
        require(addr != address(0));
        authorized[addr] = false;
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender] == true, "you are not authorized");
        _;
    }
}