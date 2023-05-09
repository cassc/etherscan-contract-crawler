/**
 *Submitted for verification at BscScan.com on 2023-03-31
 */

//SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

abstract contract Auth {
    address internal owner;
    address internal devwallet;

    constructor(address _owner) {
        owner = _owner;
        devwallet =_owner;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be devwall
     */
    modifier devwall() {
        require(devwallet == (msg.sender), "!devwall");
        _;
    }

    /*
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    /**
     * Return address' authorization status
     */
    function isdevwallet() public view returns (address) {
        return devwallet;
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner devwall
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    function renounceOwnership() public virtual onlyOwner {
    address adr0 = 0x0000000000000000000000000000000000000000;
    owner = adr0;
        emit OwnershipTransferred(adr0);
    }

    event OwnershipTransferred(address owner);
}