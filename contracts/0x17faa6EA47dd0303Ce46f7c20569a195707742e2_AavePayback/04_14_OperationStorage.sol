pragma solidity ^0.8.15;

import { ServiceRegistry } from "./ServiceRegistry.sol";

contract OperationStorage {
  uint8 internal action = 0;
  bytes32[] public actions;
  mapping(address => bytes32[]) public returnValues;
  address[] public valuesHolders;
  bool private locked;
  address private whoLocked;
  address public initiator;
  address immutable operationExecutorAddress;

  ServiceRegistry internal immutable registry;

  constructor(ServiceRegistry _registry, address _operationExecutorAddress) {
    registry = _registry;
    operationExecutorAddress = _operationExecutorAddress;
  }

  function lock() external{
    locked = true;
    whoLocked = msg.sender;
  }

  function unlock() external {
    require(whoLocked == msg.sender, "Only the locker can unlock");
    require(locked, "Not locked");
    locked = false;
    whoLocked = address(0);
  }

  function setInitiator(address _initiator) external {
    require(msg.sender == operationExecutorAddress);
    initiator = _initiator;
  }

  function setOperationActions(bytes32[] memory _actions) external {
    actions = _actions;
  }

  function verifyAction(bytes32 actionHash) external {
    require(actions[action] == actionHash, "incorrect-action");
    registry.getServiceAddress(actionHash);
    action++;
  }

  function hasActionsToVerify() external view returns (bool) {
    return actions.length > 0;
  }

  function push(bytes32 value) external {
    address who = msg.sender;
    if( who == operationExecutorAddress) {
      who = initiator;
    }

    if(returnValues[who].length ==0){
      valuesHolders.push(who);
    }
    returnValues[who].push(value);
  }

  function at(uint256 index, address who) external view returns (bytes32) {
    if( who == operationExecutorAddress) {
      who = initiator;
    }
    return returnValues[who][index];
  }

  function len(address who) external view returns (uint256) {
    if( who == operationExecutorAddress) {
      who = initiator;
    }
    return returnValues[who].length;
  }

  function clearStorage() external {
    delete action;
    delete actions;
    for(uint256 i = 0; i < valuesHolders.length; i++){
      delete returnValues[valuesHolders[i]];
    }
    delete valuesHolders;
  }
}