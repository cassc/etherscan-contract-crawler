// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

abstract contract Auth {

    event SetOwner(address indexed owner);
    event SetTrusted(address indexed user, bool isTrusted);

    address public owner;

    mapping(address => bool) public trusted;

    error OnlyOwner();
    error OnlyTrusted();

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyTrusted() {
        if (!trusted[msg.sender]) revert OnlyTrusted();
        _;
    }

    constructor(address newOwner, address trustedUser) {
        owner = newOwner;
        trusted[trustedUser] = true;

        emit SetOwner(owner);
        emit SetTrusted(trustedUser, true);
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
        emit SetOwner(newOwner);
    }

    function setTrusted(address user, bool isTrusted) external onlyOwner {
        trusted[user] = isTrusted;
        emit SetTrusted(user, isTrusted);
    }

}