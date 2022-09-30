// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @title Ownable
 * @dev Set & change owner
 */
contract Ownable is Context{

    address private owner;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = _msgSender();
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(owner == _msgSender(), "Caller is not owner");
        _;
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
        emit OwnerSet(owner, newOwner);
    }
} 