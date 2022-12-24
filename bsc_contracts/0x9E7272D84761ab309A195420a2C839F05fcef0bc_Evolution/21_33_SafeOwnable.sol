// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import './SafeOwnableInterface.sol';

/**
 * This is a contract copied from 'OwnableUpgradeable.sol'
 * It has the same fundation of Ownable, besides it accept pendingOwner for mor Safe Use
 */
abstract contract SafeOwnable is SafeOwnableInterface {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public override view returns (address) {
        return _owner;
    }

    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function setPendingOwner(address _addr) public onlyOwner {
        _pendingOwner = _addr;
    }

    function acceptOwner() public {
        require(msg.sender == _pendingOwner, "Ownable: caller is not the pendingOwner"); 
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}