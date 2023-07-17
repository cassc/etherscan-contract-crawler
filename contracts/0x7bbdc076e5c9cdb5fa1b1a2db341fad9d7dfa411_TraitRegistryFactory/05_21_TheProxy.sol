// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./LookupContract.sol";

// import "hardhat/console.sol";

contract TheProxy {

    event ContractInitialised(string contract_name,address dest);

    address immutable public lookup;

    constructor(string memory contract_name, address _lookup) {
        // console.log("TheProxy constructor");
        lookup = _lookup;
        address dest   = LookupContract(lookup).find_contract(contract_name);
        // console.log("proxy installed: dest/ctr_name/lookup", dest, contract_name, lookup);
        emit ContractInitialised(contract_name,dest);
    }

    // fallback(bytes calldata b) external  returns (bytes memory)  {           // For debugging when we want to access "lookup"
    fallback(bytes calldata b) external payable returns (bytes memory)  {
        // console.log("proxy start sender/lookup:", msg.sender, lookup);
        address dest   = LookupContract(lookup).lookup();
        // console.log("proxy delegate:", dest);
        (bool success, bytes memory returnedData) = dest.delegatecall(b);
        require(success, string(returnedData));
        return returnedData; 
    }
  
}