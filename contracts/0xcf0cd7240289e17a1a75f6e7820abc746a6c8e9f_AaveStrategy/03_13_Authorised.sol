// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./Owned.sol";

abstract contract Authorised is Owned {
    
    event SetAuthorised(address indexed user, bool isAuthorised);

    mapping(address => bool) public authorised;

    modifier onlyAuthorised() {
        if (!authorised[msg.sender]) revert Unauthorised();
        _;
    }

    constructor(address _owner) Owned(_owner) {
        authorised[_owner] = true;
        emit SetAuthorised(_owner, true);
    }

    function setAuthorised(address user, bool _authorised) public onlyOwner {
        authorised[user] = _authorised;
        emit SetAuthorised(user, _authorised);
    }
}