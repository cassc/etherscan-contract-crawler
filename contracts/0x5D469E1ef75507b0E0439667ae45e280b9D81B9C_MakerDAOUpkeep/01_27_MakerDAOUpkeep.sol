// SPDX-License-Identifier: MIT

/*

  Coded for MakerDAO and The Keep3r Network with ♥ by
  ██████╗░███████╗███████╗██╗  ░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
  ██╔══██╗██╔════╝██╔════╝██║  ░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
  ██║░░██║█████╗░░█████╗░░██║  ░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
  ██║░░██║██╔══╝░░██╔══╝░░██║  ░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
  ██████╔╝███████╗██║░░░░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
  ╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░
  https://defi.sucks

*/

pragma solidity >=0.8.4 <0.9.0;

import './utils/Governable.sol';
import './utils/Keep3rJob.sol';
import './utils/Pausable.sol';
import './utils/DustCollector.sol';
import '../interfaces/external/ISequencer.sol';
import '../interfaces/external/IJob.sol';
import '../interfaces/external/IKeep3rV2.sol';
import '../interfaces/IMakerDAOUpkeep.sol';

contract MakerDAOUpkeep is IMakerDAOUpkeep, Governable, Keep3rJob, Pausable, DustCollector {
  address public override sequencer = 0x9566eB72e47E3E20643C0b1dfbEe04Da5c7E4732;
  bytes32 public override network;

  constructor(address _governor, bytes32 _network) Governable(_governor) Keep3rJob() {
    network = _network;
  }

  function work(address _job, bytes calldata _data) external override validateAndPayKeeper(msg.sender) {
    if (paused) revert Paused();
    if (!ISequencer(sequencer).hasJob(_job)) revert NotValidJob();
    IJob(_job).work(network, _data);
  }

  function setNetwork(bytes32 _network) external override onlyGovernor {
    network = _network;
    emit NetworkSet(network);
  }

  function setSequencerAddress(address _sequencer) external override onlyGovernor {
    sequencer = _sequencer;
    emit SequencerAddressSet(sequencer);
  }
}