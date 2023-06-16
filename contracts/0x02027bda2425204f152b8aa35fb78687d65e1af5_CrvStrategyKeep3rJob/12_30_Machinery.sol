// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import '../../interfaces/utils/IMachinery.sol';
import '../../interfaces/mechanics/IMechanicsRegistry.sol';

abstract
contract Machinery is IMachinery {
  using EnumerableSet for EnumerableSet.AddressSet;

  IMechanicsRegistry internal MechanicsRegistry;

  constructor(address _mechanicsRegistry) public {
    _setMechanicsRegistry(_mechanicsRegistry);
  }

  function _setMechanicsRegistry(address _mechanicsRegistry) internal {
    MechanicsRegistry = IMechanicsRegistry(_mechanicsRegistry);
  }

  // View helpers
  function mechanicsRegistry() external view override returns (address _mechanicRegistry) {
    return address(MechanicsRegistry);
  }
  function isMechanic(address _mechanic) public view override returns (bool _isMechanic) {
    return MechanicsRegistry.isMechanic(_mechanic);
  }

}