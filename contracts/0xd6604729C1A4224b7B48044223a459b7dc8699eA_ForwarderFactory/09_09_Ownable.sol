// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "./Errors.sol";

abstract contract Ownable {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        if (_owner != msg.sender) {
            revert Unauthorised();
        }

        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnerZeroAddress();
        }

        _owner = newOwner;
    }
}