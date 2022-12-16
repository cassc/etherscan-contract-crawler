// SPDX-License-Identifier: ISC
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract Modular {
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private moduleSet;

  event ModuleAdded(address module);
  event ModuleRemoved(address module);
  
  function _addModule(address module) internal {
    if (moduleSet.add(module)) {
      emit ModuleAdded(module);
    }
  }

  function _removeModule(address module) internal {
    if (moduleSet.remove(module)) {
      emit ModuleRemoved(module);
    }
  }

  function isModule(address module) public view returns (bool) {
    return moduleSet.contains(module);
  }

  // see warnings for Set.values()
  function getModules() public view returns (address[] memory) {
    return moduleSet.values();
  }

  modifier onlyModule {
    require(isModule(msg.sender));
    _;
  }
}