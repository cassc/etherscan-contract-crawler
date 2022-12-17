// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./P2PDividends.sol";

contract P2PDividendsFactory is Ownable {
    using Clones for address;

    address public implementation;

    event UpdateImplementation(address indexed newImplementation, address indexed oldImplementation);

    event CreateP2PDividends(address indexed contractAddress, address indexed manager, address indexed asset);

    constructor(address impl_) Ownable() {
        _updateImpl(impl_);
    }

    function create(address manager_, address asset_) external returns (address contractAddress) {
        contractAddress = implementation.clone();
        P2PDividends(contractAddress).initialize(manager_, asset_);
        emit CreateP2PDividends(contractAddress, manager_, asset_);
    }

    function updateImplementation(address impl_) external onlyOwner {
        address prevImpl_ = implementation;
        _updateImpl(impl_);
        emit UpdateImplementation(impl_, prevImpl_);
    }

    function _updateImpl(address impl_) private {
        implementation = impl_;
    }
}