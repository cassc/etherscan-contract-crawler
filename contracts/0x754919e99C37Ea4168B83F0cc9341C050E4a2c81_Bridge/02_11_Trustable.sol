// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Trustable is Ownable {

    mapping(address=>bool) public _isTrusted;

    modifier onlyTrusted {
        require(_isTrusted[msg.sender] || msg.sender == owner(), "not trusted");
        _;
    }

    function addTrusted(address user) public onlyOwner {
        _isTrusted[user] = true;
    }

    function removeTrusted(address user) public onlyOwner {
        _isTrusted[user] = false;
    }
}