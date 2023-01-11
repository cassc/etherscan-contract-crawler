// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-721-delegate/contracts/interfaces/IJBTiered721DelegateDeployer.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController.sol';
import '../structs/DefifaLaunchProjectData.sol';
import '../structs/DefifaDelegateData.sol';
import '../structs/DefifaTimeData.sol';

interface IDefifaDeployer {
  function SPLIT_PROJECT_ID() external view returns (uint256);

  function SPLIT_DOMAIN() external view returns (uint256);

  function token() external view returns (address);

  function controller() external view returns (IJBController);

  function protocolFeeProjectTokenAccount() external view returns (address);

  function timesFor(uint256 _gameId) external view returns (DefifaTimeData memory);

  function mintDurationOf(uint256 _gameId) external view returns (uint256);

  function startOf(uint256 _gameId) external view returns (uint256);

  function refundPeriodDurationOf(uint256 _gameId) external view returns (uint256);

  function endOf(uint256 _gameId) external view returns (uint256);

  function terminalOf(uint256 _gameId) external view returns (IJBPaymentTerminal);

  function distributionLimit(uint256 _gameId) external view returns (uint256);

  function holdFeesDuring(uint256 _gameId) external view returns (bool);

  function currentGamePhaseOf(uint256 _gameId) external view returns (uint256);

  function nextPhaseNeedsQueueing(uint256 _gameId) external view returns (bool);

  function launchGameWith(
    DefifaDelegateData calldata _delegateData,
    DefifaLaunchProjectData calldata _launchProjectData
  ) external returns (uint256 projectId);

  function queueNextPhaseOf(uint256 _projectId) external returns (uint256 configuration);

  function claimProtocolProjectToken() external;
}