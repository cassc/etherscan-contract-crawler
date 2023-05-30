// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { Operation } from "./types/Common.sol";
import { OPERATIONS_REGISTRY } from "./constants/Common.sol";

struct StoredOperation {
  bytes32[] actions;
  bool[] optional;
  string name;
}

/**
 * @title Operation Registry
 * @notice Stores the Actions that constitute a given Operation and information if an Action can be skipped

 */
contract OperationsRegistry {
  mapping(string => StoredOperation) private operations;
  address public owner;

  modifier onlyOwner() {
    require(msg.sender == owner, "only-owner");
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  /**
   * @notice Stores the Actions that constitute a given Operation
   * @param newOwner The address of the new owner of the Operations Registry
   */
  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

  /**
   * @dev Emitted when a new operation is added or an existing operation is updated
   * @param name The Operation name
   **/
  event OperationAdded(bytes32 indexed name);

  /**
   * @notice Adds an Operation's Actions keyed to a an operation name
   * @param operation Struct with Operation name, actions and their optionality
   */
  function addOperation(StoredOperation calldata operation) external onlyOwner {
    operations[operation.name] = operation;
    // By packing the string into bytes32 which means the max char length is capped at 64
    emit OperationAdded(bytes32(abi.encodePacked(operation.name)));
  }

  /**
   * @notice Gets an Operation from the Registry
   * @param name The name of the Operation
   * @return actions Returns an array of Actions and array for optionality of coresponding Actions
   */
  function getOperation(
    string memory name
  ) external view returns (bytes32[] memory actions, bool[] memory optional) {
    if (keccak256(bytes(operations[name].name)) == keccak256(bytes(""))) {
      revert("Operation doesn't exist");
    }
    actions = operations[name].actions;
    optional = operations[name].optional;
  }
}