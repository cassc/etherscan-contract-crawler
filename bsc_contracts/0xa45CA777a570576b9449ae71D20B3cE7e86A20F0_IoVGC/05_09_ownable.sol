pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT

// This contract is used to determine owner of other contracts.
// At the deploy time, the owner is set to the account that deploys the contract.
contract ownable {
    address payable owner;

    modifier isOwner {
        require(owner == msg.sender,"You should be owner to call this function.");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

// This function is used to change the owner of the contract.
    function changeOwner(address payable _owner) public isOwner {
        require(owner != _owner,"You must enter a new value.");
        owner = _owner;
    }

// This function returns the owner address of the contract.
    function getOwner() public view returns(address) {
        return(owner);
    }

}