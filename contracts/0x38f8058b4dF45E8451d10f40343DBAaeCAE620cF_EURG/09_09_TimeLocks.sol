// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";


/**
* @title TimeLocks
* @author Geminon Protocol
* @dev Utility to protect smart contracts against instant changes
* on critical infrastructure. Sets a two step procedure to change
* the address of a smart contract that is used by another contract.
*/
contract TimeLocks is Ownable {

    struct ContractChangeRequest {
        bool changeRequested;
        uint64 timestampRequest;
        address newAddressRequested;
    }

    mapping(address => ContractChangeRequest) public changeRequests;

    
    /// @dev Creates a request to change the address of a smart contract.
    function requestAddressChange(address actualContract, address newContract) 
        external 
        onlyOwner 
    {
        require(newContract != address(0)); // dev: address 0
        
        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: newContract
            });
        
        changeRequests[actualContract] = changeRequest;
    }

    /// @dev Creates a request to add a new address of a smart contract.
    function requestAddAddress(address newContract) external onlyOwner {
        require(newContract != address(0)); // dev: address 0

        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: newContract
            });
        
        changeRequests[address(0)] = changeRequest;
    }

    /// @dev Creates a request to remove the address of a smart contract.
    function requestRemoveAddress(address oldContract) external onlyOwner {
        require(oldContract != address(0)); // dev: address zero
        
        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: address(0)
            });
        
        changeRequests[oldContract] = changeRequest;
    }
}