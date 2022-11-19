//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/AccessControl.sol";

// File contracts/ContractRegistryInterface.sol

pragma solidity ^0.8.3;

interface ContractRegistryInterface {
  function get(string memory contractName) external view returns (address);
}


// File contracts/ContractRegistry.sol

pragma solidity ^0.8.3;

contract ContractRegistry is ContractRegistryInterface, AccessControl {
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");
  event Set(string contractName, address contractAddress);

  mapping(string => address) contracts;
  
  function get(string calldata contractName) external view override(ContractRegistryInterface) returns (address) {
    address addy = contracts[contractName];
    require(addy != address(0), string(abi.encodePacked("ContractRegistry: missing contract - ", contractName)));
    return addy;
  }

  function set(string calldata contractName, address contractAddress) external onlyRole(MANAGER_ROLE) {
    contracts[contractName] = contractAddress;
    emit Set(contractName, contractAddress);
  }

  constructor(address adminAddress) {
    _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
  }
}