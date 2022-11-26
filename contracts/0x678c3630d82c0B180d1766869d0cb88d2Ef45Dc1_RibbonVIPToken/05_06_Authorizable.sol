// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Authorizable is Ownable {

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[_msgSender()], "Authorizable: caller is not authorized");
        _;
    }

    function addAuthorized(address toAdd) onlyOwner public {
        require(toAdd != address(0));
        authorized[toAdd] = true;
    }

    function removeAuthorized(address toRemove) onlyOwner public {
        require(toRemove != address(0));
        authorized[toRemove] = false;
    }

}