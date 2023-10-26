// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {SafeCast} from 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {ICrossDomainMessenger} from './interfaces/ICrossDomainMessenger.sol';
import {BaseAdapter, IBaseAdapter} from '../BaseAdapter.sol';
import {Errors} from '../../libs/Errors.sol';
import {IOpAdapter} from './IOpAdapter.sol';
import {ChainIds} from '../../libs/ChainIds.sol';

/**
 * @title OpAdapter
 * @author BGD Labs
 * @notice Optimism bridge adapter. Used to send and receive messages cross chain between Ethereum and Optimism
 * @dev it uses the eth balance of CrossChainController contract to pay for message bridging as the method to bridge
        is called via delegate call
 * @dev note that this adapter is can only be used for the communication path ETHEREUM -> OPTIMISM
 */
contract OpAdapter is IOpAdapter, BaseAdapter {
  /// @inheritdoc IOpAdapter
  address public immutable OVM_CROSS_DOMAIN_MESSENGER;

  /**
   * @notice only calls from the set ovm are accepted.
   */
  modifier onlyOVM() {
    require(msg.sender == address(OVM_CROSS_DOMAIN_MESSENGER), Errors.CALLER_NOT_OVM);
    _;
  }

  /**
   * @param crossChainController address of the cross chain controller that will use this bridge adapter
   * @param ovmCrossDomainMessenger optimism entry point address
   * @param trustedRemotes list of remote configurations to set as trusted
   */
  constructor(
    address crossChainController,
    address ovmCrossDomainMessenger,
    TrustedRemotesConfig[] memory trustedRemotes
  ) BaseAdapter(crossChainController, trustedRemotes) {
    OVM_CROSS_DOMAIN_MESSENGER = ovmCrossDomainMessenger;
  }

  /// @inheritdoc IBaseAdapter
  function forwardMessage(
    address receiver,
    uint256 destinationGasLimit,
    uint256 destinationChainId,
    bytes calldata message
  ) external virtual returns (address, uint256) {
    require(
      isDestinationChainIdSupported(destinationChainId),
      Errors.DESTINATION_CHAIN_ID_NOT_SUPPORTED
    );
    require(receiver != address(0), Errors.RECEIVER_NOT_SET);

    ICrossDomainMessenger(OVM_CROSS_DOMAIN_MESSENGER).sendMessage(
      receiver,
      abi.encodeWithSelector(IOpAdapter.ovmReceive.selector, message),
      SafeCast.toUint32(destinationGasLimit) // for now gas fees are paid on optimism ( < 1.9) and metis (<5M) but its subject to change
    );

    return (OVM_CROSS_DOMAIN_MESSENGER, 0);
  }

  /// @inheritdoc IOpAdapter
  function ovmReceive(bytes calldata message) external onlyOVM {
    uint256 originChainId = getOriginChainId();
    address srcAddress = ICrossDomainMessenger(OVM_CROSS_DOMAIN_MESSENGER).xDomainMessageSender();
    require(
      _trustedRemotes[originChainId] == srcAddress && srcAddress != address(0),
      Errors.REMOTE_NOT_TRUSTED
    );

    _registerReceivedMessage(message, originChainId);
  }

  /// @inheritdoc IOpAdapter
  function getOriginChainId() public pure virtual returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  /// @inheritdoc IOpAdapter
  function isDestinationChainIdSupported(uint256 chainId) public view virtual returns (bool) {
    return chainId == ChainIds.OPTIMISM;
  }

  /// @inheritdoc IBaseAdapter
  function nativeToInfraChainId(uint256 nativeChainId) public pure override returns (uint256) {
    return nativeChainId;
  }

  /// @inheritdoc IBaseAdapter
  function infraToNativeChainId(uint256 infraChainId) public pure override returns (uint256) {
    return infraChainId;
  }
}