// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IRegistry.sol";
// import "hardhat/console.sol";

contract LookupContract {

    IRegistry           reg = IRegistry(0x1e8150050A7a4715aad42b905C08df76883f396F);

    mapping(address => address) lookups;

    error ContractNameNotInitialised(string contract_name);
    error ContractInfoNotInitialised();

    function find_contract(string memory contract_name) external returns (address) {
        // console.log("find_contract called for:", contract_name);
        address adr = reg.getRegistryAddress(contract_name);
        if (adr == address(0)) revert ContractNameNotInitialised(contract_name);
        lookups[msg.sender] = adr;
        return adr;
    }

    function lookup() external view returns (address) {
        address adr = lookups[msg.sender];
        // console.log("lookup called sender/adr", msg.sender, adr);
        if (adr == address(0)) revert ContractInfoNotInitialised();
        return adr;
    }
}