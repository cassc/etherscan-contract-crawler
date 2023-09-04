/**
 *Submitted for verification at Etherscan.io on 2023-08-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


interface IRegistry {
    function setRegistryAddress(string memory fn, address value) external ;
    function setRegistryBool(string memory fn, bool value) external ;
    function setRegistryUINT(string memory key) external view returns (uint256) ;
    function setRegistryString(string memory fn, string memory value) external ;
    function setAdmin(address user,bool status ) external;
    function setAppAdmin(address app, address user, bool state) external;

    function getRegistryAddress(string memory key) external view returns (address) ;
    function getRegistryBool(string memory key) external view returns (bool);
    function getRegistryUINT(string memory key) external view returns (uint256) ;
    function getRegistryString(string memory key) external view returns (string memory) ;
    function isAdmin(address user) external view returns (bool) ;
    function isAppAdmin(address app, address user) external view returns (bool);
}


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