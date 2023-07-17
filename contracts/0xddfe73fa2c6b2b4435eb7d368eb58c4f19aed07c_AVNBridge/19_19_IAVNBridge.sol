// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IAVNBridge {
  event LogGrowthDenied(uint32 period);
  event LogGrowthDelayUpdated(uint256 oldDelaySeconds, uint256 newDelaySeconds);
  event LogQuorumUpdated(uint256[2] quorum);
  event LogValidatorFunctionsAreEnabled(bool state);
  event LogLiftingIsEnabled(bool state);
  event LogLoweringIsEnabled(bool state);
  event LogLowerCallUpdated(bytes2 callId, uint256 numBytes);

  event LogValidatorRegistered(bytes32 indexed t1PublicKeyLHS, bytes32 t1PublicKeyRHS, bytes32 indexed t2PublicKey,
      uint256 indexed t2TransactionId);
  event LogValidatorDeregistered(bytes32 indexed t1PublicKeyLHS, bytes32 t1PublicKeyRHS, bytes32 indexed t2PublicKey,
      uint256 indexed t2TransactionId);
  event LogRootPublished(bytes32 indexed rootHash, uint256 indexed t2TransactionId);

  event LogLifted(address indexed token, address indexed t1Address, bytes32 indexed t2PublicKey, uint256 amount);
  event LogLowered(address indexed token, address indexed t1Address, bytes32 indexed t2PublicKey, uint256 amount);
  event LogGrowthTriggered(uint256 indexed amount, uint32 indexed period, uint256 indexed releaseTime);
  event LogGrowth(uint256 indexed amount, uint32 indexed period);

  // Owner only
  function loadValidators(address[] calldata t1Address, bytes32[] calldata t1PublicKeyLHS, bytes32[] calldata t1PublicKeyRHS,
      bytes32[] calldata t2PublicKey) external;
  function setCoreOwner() external;
  function denyGrowth(uint32 period) external;
  function setGrowthDelay(uint256 delaySeconds) external;
  function setQuorum(uint256[2] memory quorum) external;
  function toggleValidatorFunctions(bool state) external;
  function toggleLifting(bool state) external;
  function toggleLowering(bool state) external;
  function updateLowerCall(bytes2 callId, uint256 numBytes) external;

  // Owner or validators only
  function triggerGrowth(uint128 amount, uint32 period, uint256 t2TransactionId, bytes calldata confirmations) external;

  // Validators only
  function registerValidator(bytes memory t1PublicKey, bytes32 t2PublicKey, uint256 t2TransactionId,
      bytes calldata confirmations) external;
  function deregisterValidator(bytes memory t1PublicKey, bytes32 t2PublicKey, uint256 t2TransactionId,
      bytes calldata confirmations) external;
  function publishRoot(bytes32 rootHash, uint256 t2TransactionId, bytes calldata confirmations) external;

  // Public
  function releaseGrowth(uint32 period) external;
  function lift(address erc20Address, bytes calldata t2PublicKey, uint256 amount) external;
  function liftETH(bytes calldata t2PublicKey) external payable;
  function lower(bytes memory leaf, bytes32[] calldata merklePath) external;
  function confirmAvnTransaction(bytes32 leafHash, bytes32[] memory merklePath) external view returns (bool);
}