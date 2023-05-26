// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SimpleAccess is Ownable {
    
    constructor() Ownable() {}
    
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(
            authorized[msg.sender] || msg.sender == owner(),
            "Sender is not authorized"
        );
        _;
    }

    function setAuthorized(address _auth, bool _isAuth) external virtual onlyOwner {
        authorized[_auth] = _isAuth;
    }
}