// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DCNTRegistry {
  using EnumerableSet for EnumerableSet.AddressSet;

  mapping(address => EnumerableSet.AddressSet) private contracts;

  /// ============ Events ============

  event Register(
    address indexed deployer,
    address indexed deployment,
    string key
  );

  event Remove(address indexed deployer, address indexed deployment);

  /// ============ Constructor ============

  constructor() {}

  /// ============ Functions ============

  function register(
    address _deployer,
    address _deployment,
    string calldata _key
  ) external {
    bool registered = contracts[_deployer].add(_deployment);
    require(registered, "Registration was unsuccessful");
    emit Register(_deployer, _deployment, _key);
  }

  function remove(address _deployer, address _deployment) external {
    bool removed = contracts[_deployer].remove(_deployment);
    require(removed, "Removal was unsuccessful");
    emit Remove(_deployer, _deployment);
  }

  function query(address _deployer) external view returns (address[] memory) {
    return contracts[_deployer].values();
  }
}