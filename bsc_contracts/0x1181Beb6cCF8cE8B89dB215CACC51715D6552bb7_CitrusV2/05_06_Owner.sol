// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract Owned {
    // address public owner; // Address of owners
    uint256 public noOfOwners; // It'll return No of Owners
    mapping(address => bool) public isOwner; // It return true if address is any owner  


     /**
     *  Throws if called by any account other than the owners.
     */

    modifier onlyOwners() {
        require(
            isOwner[msg.sender], 
            "PROMPT 2015: Access denied! Only owners can perform this activity!"
        );
        _;
    }

     /**
     *  Throws if called by any account other than the users.
     */

    modifier onlyUsers(){
        require(
            !isOwner[msg.sender], 
            "PROMPT 2016: Access denied! Only users can perform this activity!"
        );
        _;
    }

    /**
     * This function add Owners through the Proposal
     * It can be called by Owners 
     */

    function addOwner(address _addNewOwner) 
        internal 
    {
        require(
            !isOwner[_addNewOwner], 
            "PROMPT 2017: Owner already added!"
        );
        
        isOwner[_addNewOwner] = true;
        noOfOwners++;
    }

    /**
     * This function remove Owners through the Proposal
     * It can be called by Owners 
     */

    function removeOwner(address _removeOwner) 
        internal 
    {
        require(
            isOwner[_removeOwner], 
            "PROMPT 2018: Owner already removed!"
        );

        isOwner[_removeOwner] = false;
        noOfOwners--;
    }
}