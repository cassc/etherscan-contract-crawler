//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {IOracleSidechain} from '../IOracleSidechain.sol';

interface IBridgeSenderAdapter {
  // FUNCTIONS

  function bridgeObservations(
    address _to,
    uint32 _destinationDomainId,
    IOracleSidechain.ObservationData[] memory _observationsData,
    bytes32 _poolSalt,
    uint24 _poolNonce
  ) external payable;

  // ERRORS

  error OnlyDataFeed();
}