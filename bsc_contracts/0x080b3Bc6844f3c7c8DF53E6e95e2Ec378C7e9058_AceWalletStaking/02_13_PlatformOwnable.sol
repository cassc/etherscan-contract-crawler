// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract PlatformOwnable is Context {
    address private _platformOwner; // address that incharge of updating state

    constructor(address owner) {
        require(owner != address(0), "invalid address");
        _platformOwner = owner;
    }

    event SetPlatformOwner(address previousOwner, address newOwner);

    modifier onlyPlatformOwner() {
        require(_msgSender() == platformOwner(), "unauthorize access");
        _;
    }

    function platformOwner() public view virtual returns (address) {
        return _platformOwner;
    }

    function transferPlatformOwner(address owner) external onlyPlatformOwner {
        require(owner != address(0), "invalid address");

        address previous = _platformOwner;
        _platformOwner = owner;

        emit SetPlatformOwner(previous, owner);
    }
}