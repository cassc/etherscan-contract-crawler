//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {IConnext, IConnextSenderAdapter, IBridgeSenderAdapter, IDataFeed, IOracleSidechain} from '../../interfaces/bridges/IConnextSenderAdapter.sol';
import {LibConnextStorage, TransferInfo} from '@connext/nxtp-contracts/contracts/core/connext/libraries/LibConnextStorage.sol';

contract ConnextSenderAdapter is IConnextSenderAdapter {
  /// @inheritdoc IConnextSenderAdapter
  IDataFeed public immutable dataFeed;

  /// @inheritdoc IConnextSenderAdapter
  IConnext public immutable connext;

  constructor(IDataFeed _dataFeed, IConnext _connext) {
    if (address(_dataFeed) == address(0) || address(_connext) == address(0)) revert ZeroAddress();
    dataFeed = _dataFeed;
    connext = _connext;
  }

  /// @inheritdoc IBridgeSenderAdapter
  function bridgeObservations(
    address _to,
    uint32 _destinationDomainId,
    IOracleSidechain.ObservationData[] memory _observationsData,
    bytes32 _poolSalt,
    uint24 _poolNonce
  ) external payable onlyDataFeed {
    bytes memory _callData = abi.encode(_observationsData, _poolSalt, _poolNonce);

    connext.xcall{value: msg.value}({
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