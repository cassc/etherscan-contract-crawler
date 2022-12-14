//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.8 <0.9.0;

import {LibConnextStorage, TransferInfo} from '@connext/nxtp-contracts/contracts/core/connext/libraries/LibConnextStorage.sol';
import {IConnext, IConnextSenderAdapter, IDataFeed, IBridgeSenderAdapter, IOracleSidechain} from '../../interfaces/bridges/IConnextSenderAdapter.sol';

contract ConnextSenderAdapter is IConnextSenderAdapter {
  /// @inheritdoc IConnextSenderAdapter
  IConnext public immutable connext;

  /// @inheritdoc IConnextSenderAdapter
  IDataFeed public immutable dataFeed;

  constructor(IConnext _connext, IDataFeed _dataFeed) {
    connext = _connext;
    dataFeed = _dataFeed;
  }

  /// @inheritdoc IBridgeSenderAdapter
  function bridgeObservations(
    address _to,
    uint32 _destinationDomainId,
    IOracleSidechain.ObservationData[] memory _observationsData,
    bytes32 _poolSalt,
    uint24 _poolNonce // TODO: review input parameters packing KMC-
  ) external payable onlyDataFeed {
    bytes memory _callData = abi.encode(_observationsData, _poolSalt, _poolNonce);

    connext.xcall({
      _destination: _destinationDomainId, // unique identifier for destination domain
      _to: _to, // recipient of funds, where calldata will be executed
      _asset: address(0), // asset being transferred
      _delegate: address(0), // permissioned address to recover in edgecases on destination domain
      _amount: 0, // amount being transferred
      _slippage: 0, // slippage in bps
      _callData: _callData // to be executed on _to on the destination domain
    });
  }

  modifier onlyDataFeed() {
    if (msg.sender != address(dataFeed)) revert OnlyDataFeed();
    _;
  }
}