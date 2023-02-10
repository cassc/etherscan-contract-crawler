pragma solidity ^0.8.13;

import "./lookup.sol";

import "hardhat/console.sol";

contract theproxy {

    event ContractInitialised(string contract_name,address dest);

    constructor(string memory contract_name) {
        address lookup = 0xb238DE0619C7e9AA155D9a69b9E5b0d9b5b41271;
        address dest   = lookup_contract(lookup).find_contract(contract_name);
        emit ContractInitialised(contract_name,dest);
    }

    fallback(bytes calldata b) external payable returns (bytes memory)  {
        address lookup = 0xb238DE0619C7e9AA155D9a69b9E5b0d9b5b41271;
        address dest   = lookup_contract(lookup).lookup();
        (bool success, bytes memory returnedData) = dest.delegatecall(b);
        require(success, string(returnedData));
        return returnedData; 
    }

  
}