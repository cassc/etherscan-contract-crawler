/**
  * ControlPlane01.sol
  * Registers the current global params
 */
pragma solidity 0.8.3;

interface IControlPlane01 {


  function whitelistedIntermediaries(address target) external returns (bool result);
  function whitelistedFactory() external returns (address result);
  function feeBps() external returns (uint32 result);
}