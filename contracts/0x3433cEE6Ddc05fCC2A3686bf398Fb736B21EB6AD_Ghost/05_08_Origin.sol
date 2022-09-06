// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Origin {
    address private _address;
    address private _provenance; 

    event Move(address indexed previousAddress, address indexed newAddress);
    event Relinquish(address provenance);

    modifier onlyOrigin() {
        bool active = _address == msg.sender && _address != address(0);
        require(active, "Caller is not the ORIGIN");
        _;
    }

    function originAddress() public view returns (address) { 
        return _address; 
    }    
    
    function originProvenance() public view returns (address) { 
        return _provenance; 
    }

    function moveOrigin(address newAddress) external onlyOrigin {
        address previousAddress = _address;
        _address = newAddress;
        emit Move(previousAddress, newAddress);
    }

    function relinquishOrigin() external onlyOrigin {
        _provenance = _address;
        _address = address(0);
        emit Relinquish(_provenance);
    }

    constructor(address addr) {
        _address = addr;
    }
}