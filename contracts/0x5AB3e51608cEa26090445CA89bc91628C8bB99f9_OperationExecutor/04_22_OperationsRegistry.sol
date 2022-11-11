pragma solidity ^0.8.15;

import { Operation } from "./types/Common.sol";
import { OPERATIONS_REGISTRY } from "./constants/Common.sol";

struct StoredOperation {
  bytes32[] actions;
  string name;
}

/**
 * @title Operation Registry
 * @notice Stores the Actions that constitute a given Operation
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
  event OperationAdded(string name);

  /**
   * @notice Adds an Operation's Actions keyed to a an operation name
   * @param name The Operation name
   * @param actions An array the Actions the Operation consists of
   */
  function addOperation(string memory name, bytes32[] memory actions) external onlyOwner {
    operations[name] = StoredOperation(actions, name);
    emit OperationAdded(name);
  }

  /**
   * @notice Gets an Operation from the Registry
   * @param name The name of the Operation
   * @return actions Returns an array of Actions
   */
  function getOperation(string memory name) external view returns (bytes32[] memory actions) {
    if (keccak256(bytes(operations[name].name)) == keccak256(bytes(""))) {
      revert("Operation doesn't exist");
    }
    actions = operations[name].actions;
  }
}