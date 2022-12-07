//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

abstract contract Auth {
    address internal _owner;
    mapping (address => bool) internal authorizations;

    constructor(address initialOwner) {
        _owner = initialOwner;
        authorizations[initialOwner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "not-owner"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "not-authorized"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable nextOwner) public onlyOwner {
        _owner = nextOwner;
        authorizations[nextOwner] = true;
        emit OwnershipTransferred(nextOwner);
    }

    event OwnershipTransferred(address owner);
}