pragma solidity ^0.8.15;

interface Executable {
  function execute(bytes calldata data, uint8[] memory paramsMap) external payable;

  /**
   * @dev Emitted once an Action has completed execution
   * @param name The Action name
   * @param returned The value returned by the Action
   **/
  event Action(string name, bytes32 returned);
}