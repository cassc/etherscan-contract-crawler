//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {IOracleSidechain} from '../IOracleSidechain.sol';

interface IBridgeSenderAdapter {
  /// @notice Bridges observations across chains
  /// @param _to Address of the target contract to xcall
  /// @param _destinationDomainId Domain id of the destination chain
  /// @param _observationsData Array of tuples representing broadcast dataset
  /// @param _poolSalt Identifier of the pool
  /// @param _poolNonce Nonce identifier of the dataset
  function bridgeObservations(
    address _to,
    uint32 _destinationDomainId,
    IOracleSidechain.ObservationData[] memory _observationsData,
    bytes32 _poolSalt,
    uint24 _poolNonce
  ) external payable;
}