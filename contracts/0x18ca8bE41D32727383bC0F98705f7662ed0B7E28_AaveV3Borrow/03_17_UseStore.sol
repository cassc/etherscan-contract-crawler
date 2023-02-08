// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { OperationStorage } from "../../core/OperationStorage.sol";
import { ServiceRegistry } from "../../core/ServiceRegistry.sol";
import { OPERATION_STORAGE } from "../../core/constants/Common.sol";

/**
 * @title UseStore contract
 * @notice Provides access to the OperationStorage contract
 * @dev Is used by Action contracts to store and retrieve values from Operation Storage.
 * @dev Previously stored values are used to override values passed to Actions during Operation execution
 */
abstract contract UseStore {
  ServiceRegistry internal immutable registry;

  constructor(address _registry) {
    registry = ServiceRegistry(_registry);
  }

  function store() internal view returns (OperationStorage) {
    return OperationStorage(registry.getRegisteredService(OPERATION_STORAGE));
  }
}

library Read {
  function read(
    OperationStorage _storage,
    bytes32 param,
    uint256 paramMapping,
    address who
  ) internal view returns (bytes32) {
    if (paramMapping > 0) {
      return _storage.at(paramMapping - 1, who);
    }

    return param;
  }

  function readUint(
    OperationStorage _storage,
    bytes32 param,
    uint256 paramMapping,
    address who
  ) internal view returns (uint256) {
    return uint256(read(_storage, param, paramMapping, who));
  }
}

library Write {
  function write(OperationStorage _storage, bytes32 value) internal {
    _storage.push(value);
  }
}