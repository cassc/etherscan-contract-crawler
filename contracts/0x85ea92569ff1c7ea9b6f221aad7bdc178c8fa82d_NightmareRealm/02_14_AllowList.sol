// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/access/Ownable.sol";

contract AllowList is Ownable {
    mapping(address => bool) allowList;

    modifier onlyAllowList() {
        require(isAllowList(msg.sender));
        _;
    }
    /**
    * add an address to the AL
    */
    function allowAdress(address _address) public onlyOwner {
        allowList[_address] = true;
    }

    /**
    * add an array of address to the AL
    */
    function addAdresses(address[] calldata _address) external onlyOwner {
        uint length = _address.length;
        for (uint i=0; i<length;) {
            allowAdress(_address[i]);
            unchecked{i++;}
        }
    }
    /**
    * remove an address off the AL
    */
    function removeAdress(address _address) public onlyOwner {
        allowList[_address] = false;
    }
    /**
    * returns true if the wallet is the address is on the Allowlist.
    */
    function isAllowList(address _address) public view returns(bool) {
        return allowList[_address];
    }
}