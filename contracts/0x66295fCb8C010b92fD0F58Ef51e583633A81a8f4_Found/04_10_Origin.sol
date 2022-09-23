// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract Origin {
    address private _address;
    address private _provenance; 

    event UpdateOrigin(address indexed to);
    event RelinquishOrigin(address provenance);

    modifier onlyOrigin() {
        bool active = _address == msg.sender && _address != address(0);
        require(active, "Caller is not the origin");
        _;
    }

    function originAddress() external view returns (address) { 
        return _address; 
    }    
    
    function originProvenance() external view returns (address) { 
        return _provenance; 
    }

    function updateOrigin(address to) external onlyOrigin {
        _address = to;
        emit UpdateOrigin(to);
    }

    function relinquishOrigin() external onlyOrigin {
        _provenance = _address;
        _address = address(0);
        emit RelinquishOrigin(_provenance);
    }

    constructor(address address_) {
        _address = address_;
    }
}