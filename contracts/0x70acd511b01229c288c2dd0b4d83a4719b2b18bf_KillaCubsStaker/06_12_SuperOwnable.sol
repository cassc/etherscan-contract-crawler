// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

abstract contract SuperOwnable {
    address public owner;
    address public superOwner;

    mapping(address => bool) authorities;

    error Denied();

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address superOwner_) {
        _transferOwnership(msg.sender);
        superOwner = superOwner_;
    }

    modifier onlyOwner() {
        if (msg.sender != owner && msg.sender != superOwner) revert Denied();
        _;
    }

    modifier onlySuperOwner() {
        if (msg.sender != superOwner) revert Denied();
        _;
    }

    modifier onlyAuthority() {
        if (!authorities[msg.sender] && msg.sender != owner) revert Denied();
        _;
    }

    function transferOwnership(address addr) public virtual onlyOwner {
        _transferOwnership(addr);
    }

    function _transferOwnership(address addr) internal virtual {
        address oldOwner = owner;
        owner = addr;
        emit OwnershipTransferred(oldOwner, addr);
    }

    function setSuperOwner(address addr) public onlySuperOwner {
        if (addr == address(0)) revert Denied();
        superOwner = addr;
    }

    function toggleAuthority(address addr, bool enabled) public onlyOwner {
        authorities[addr] = enabled;
    }
}