//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Extension.sol";
import "./IRetractLogic.sol";
import { ExtendableState, ExtendableStorage } from "../../storage/ExtendableStorage.sol";
import { RoleState, Permissions } from "../../storage/PermissionStorage.sol";

contract RetractLogic is RetractExtension {
  /**
   * @dev see {Extension-constructor} for constructor
   */

  /**
   * @dev modifier that restricts caller of a function to only the most recent caller if they are `owner`
   */
  modifier onlyOwnerOrSelf() virtual {
    address owner = Permissions._getState().owner;
    require(
      _lastCaller() == owner || _lastCaller() == address(this),
      "unauthorised"
    );
    _;
  }

  /**
   * @dev see {IRetractLogic-retract}
   */
  function retract(address extension) public virtual override onlyOwnerOrSelf {
    ExtendableState storage state = ExtendableStorage._getState();

    // Search for extension in interfaceIds
    uint256 numberOfInterfacesImplemented = state
      .implementedInterfaceIds
      .length;
    bool hasMatch;

    // we start with index 1 and reduce by one due to line 43 shortening the array
    // we need to decrement the counter if we shorten the array, but uint cannot be < 0
    for (uint256 i = 1; i < numberOfInterfacesImplemented + 1; i++) {
      uint256 decrementedIndex = i - 1;
      bytes4 interfaceId = state.implementedInterfaceIds[decrementedIndex];
      address currentExtension = state.extensionContracts[interfaceId];

      // Check if extension matches the one we are looking for
      if (currentExtension == extension) {
        hasMatch = true;
        // Remove interface implementor
        delete state.extensionContracts[interfaceId];
        state.implementedInterfaceIds[decrementedIndex] = state
          .implementedInterfaceIds[numberOfInterfacesImplemented - 1];
        state.implementedInterfaceIds.pop();

        // Remove function selector implementor
        uint256 numberOfFunctionsImplemented = state
          .implementedFunctionsByInterfaceId[interfaceId]
          .length;
        for (uint256 j = 0; j < numberOfFunctionsImplemented; j++) {
          bytes4 functionSelector = state.implementedFunctionsByInterfaceId[
            interfaceId
          ][j];
          delete state.extensionContracts[functionSelector];
        }
        delete state.implementedFunctionsByInterfaceId[interfaceId];

        numberOfInterfacesImplemented--;
        i--;
      }
    }

    if (!hasMatch) {
      revert(
        "Retract: specified extension is not an extension of this contract, cannot retract"
      );
    }

    emit Retracted(extension);
  }
}