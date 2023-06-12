// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;
    bool public lpLocked;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event LPLocked();
    event LPUnlocked();

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    constructor() {
        _owner = _msgSender();
        lpLocked = false;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function lockLP() public onlyOwner {
        lpLocked = true;
        emit LPLocked();
    }

    function unlockLP() public onlyOwner {
        lpLocked = false;
        emit LPUnlocked();
    }
}