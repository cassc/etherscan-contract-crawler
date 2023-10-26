// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BaseAdapter, IBaseAdapter} from '../BaseAdapter.sol';
import {IArbitraryMessageBridge} from './IArbitraryMessageBridge.sol';
import {IGnosisChainAdapter} from './IGnosisChainAdapter.sol';
import {Errors} from '../../libs/Errors.sol';
import {ChainIds} from '../../libs/ChainIds.sol';

/**
 * @title GnosisChainAdapter
 * @author BGD Labs
 * @notice Gnosis Chain bridge adapter. Used to send and receive messages cross chain between Ethereum and Gnosis Chain.
 * @dev it uses the eth balance of CrossChainController contract to pay for message bridging as the method to bridge
        is called via delegate call
 * @dev note that this adapter can only be used for the communication path ETHEREUM -> GNOSISCHAIN
 */
contract GnosisChainAdapter is BaseAdapter, IGnosisChainAdapter {
  /// @inheritdoc IGnosisChainAdapter
  address public immutable override BRIDGE;

  /**
   * @param crossChainController address of the cross chain controller that will use this bridge adapter
   * @param arbitraryMessageBridge The Gnosis AMB contract
   * @param trustedRemotes list of remote configurations to set as trusted
   */
  constructor(
    address crossChainController,
    address arbitraryMessageBridge,
    TrustedRemotesConfig[] memory trustedRemotes
  ) BaseAdapter(crossChainController, trustedRemotes) {
    require(arbitraryMessageBridge != address(0), Errors.ZERO_GNOSIS_ARBITRARY_MESSAGE_BRIDGE);
    BRIDGE = arbitraryMessageBridge;
  }

  /// @inheritdoc IBaseAdapter
  function forwardMessage(
    address receiver,
    uint256 gasLimit,
    uint256 destinationChainId,
    bytes calldata message
  ) external override returns (address, uint256) {
    require(
      isDestinationChainIdSupported(destinationChainId),
      Errors.DESTINATION_CHAIN_ID_NOT_SUPPORTED
    );
    require(receiver != address(0), Errors.RECEIVER_NOT_SET);

    bytes memory data = abi.encodeWithSelector(this.receiveMessage.selector, message);

    IArbitraryMessageBridge(BRIDGE).requireToPassMessage(receiver, data, gasLimit);
    return (address(BRIDGE), 0);
  }

  /// @inheritdoc IGnosisChainAdapter
  function receiveMessage(bytes calldata message) external override {
    require(msg.sender == address(BRIDGE), Errors.CALLER_NOT_GNOSIS_ARBITRARY_MESSAGE_BRIDGE);
    address sourceAddress = IArbitraryMessageBridge(BRIDGE).messageSender();
    uint256 sourceChainId = IArbitraryMessageBridge(BRIDGE).messageSourceChainId();
    require(
      _trustedRemotes[sourceChainId] == sourceAddress && sourceAddress != address(0),
      Errors.REMOTE_NOT_TRUSTED
    );

    _registerReceivedMessage(message, sourceChainId);
  }

  /// @inheritdoc IGnosisChainAdapter
  function isDestinationChainIdSupported(uint256 chainId) public pure virtual returns (bool) {
    return chainId == ChainIds.GNOSIS;
  }

  /// @inheritdoc IBaseAdapter
  function nativeToInfraChainId(uint256 bridgeChainId) public pure override returns (uint256) {
    return bridgeChainId;
  }

  /// @inheritdoc IBaseAdapter
  function infraToNativeChainId(uint256 infraChainId) public pure override returns (uint256) {
    return infraChainId;
  }
}