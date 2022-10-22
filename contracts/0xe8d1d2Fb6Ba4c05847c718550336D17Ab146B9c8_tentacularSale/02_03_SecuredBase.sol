// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract SecuredBase {
    address public owner;

    error NoContractsAllowed();
    error NotContractOwner();
    
    constructor() { 
        owner=msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner=newOwner;
    }

    modifier onlyOwner() {
        if (msg.sender!=owner) revert NotContractOwner();
        _;
    }

    modifier noContracts() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        if ((msg.sender != tx.origin) || (size != 0)) revert NoContractsAllowed();
        _;
    }
}