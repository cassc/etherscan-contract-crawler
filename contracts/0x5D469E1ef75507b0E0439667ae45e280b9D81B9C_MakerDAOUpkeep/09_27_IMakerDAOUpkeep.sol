// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './utils/IGovernable.sol';
import './utils/IKeep3rJob.sol';
import './utils/IPausable.sol';
import './utils/IDustCollector.sol';

interface IMakerDAOUpkeep is IGovernable, IPausable, IKeep3rJob, IDustCollector {
  // event
  event NetworkSet(bytes32 _newNetwork);
  event SequencerAddressSet(address _newSequencerAddress);

  // errors
  error AvailableCredits();
  error Paused();
  error CallFailed();
  error NotValidJob();

  // variables

  function network() external returns (bytes32 _network);

  function sequencer() external returns (address _sequencer);

  // methods
  function work(address _job, bytes calldata _data) external;

  function setNetwork(bytes32 _network) external;

  function setSequencerAddress(address _sequencer) external;
}