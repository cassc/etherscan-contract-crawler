// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;
    address private _dev;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(address(_msgSender())); // If needing to use this for a client change to their address
        _dev = _msgSender();
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyDev() {
        _checkDev();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function dev() public view virtual returns (address) {
        return _dev;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function _checkDev() internal view virtual {
        require(dev() == _msgSender(), "Ownable: caller is not the dev");
    }

    function renounceOwnership() external virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function transferDevOwnership(address newOwner) external virtual onlyDev {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _dev = newOwner;
    }
}