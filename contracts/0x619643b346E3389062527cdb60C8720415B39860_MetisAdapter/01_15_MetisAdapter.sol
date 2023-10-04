// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BaseAdapter, IBaseAdapter} from '../BaseAdapter.sol';
import {Errors} from '../../libs/Errors.sol';
import {ChainIds} from '../../libs/ChainIds.sol';
import {OpAdapter, IOpAdapter, ICrossDomainMessenger, SafeCast} from '../optimism/OpAdapter.sol';

/**
 * @title MetisAdapter
 * @author BGD Labs
 * @notice Metis bridge adapter. Used to send and receive messages cross chain between Ethereum and Metis
 * @dev it uses the eth balance of CrossChainController contract to pay for message bridging as the method to bridge
        is called via delegate call
 * @dev note that this adapter can only be used for the communication path ETHEREUM -> METIS
 * @dev note that this adapter inherits from Optimism adapter and overrides supported chain and forwardMessage
 */
contract MetisAdapter is OpAdapter {
  /**
   * @param crossChainController address of the cross chain controller that will use this bridge adapter
   * @param ovmCrossDomainMessenger optimism entry point address
   * @param trustedRemotes list of remote configurations to set as trusted
   */
  constructor(
    address crossChainController,
    address ovmCrossDomainMessenger,
    TrustedRemotesConfig[] memory trustedRemotes
  ) OpAdapter(crossChainController, ovmCrossDomainMessenger, trustedRemotes) {}

  /// @inheritdoc IOpAdapter
  function isDestinationChainIdSupported(
    uint256 chainId
  ) public view virtual override returns (bool) {
    return chainId == ChainIds.METIS;
  }

  /// @inheritdoc IOpAdapter
  function getOriginChainId() public pure virtual override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  /// @inheritdoc IBaseAdapter
  function forwardMessage(
    address receiver,
    uint256 destinationGasLimit,
    uint256 destinationChainId,
    bytes calldata message
  ) external override returns (address, uint256) {
    require(
      isDestinationChainIdSupported(destinationChainId),
      Errors.DESTINATION_CHAIN_ID_NOT_SUPPORTED
    );
    require(receiver != address(0), Errors.RECEIVER_NOT_SET);

    ICrossDomainMessenger(OVM_CROSS_DOMAIN_MESSENGER).sendMessageViaChainId(
      destinationChainId,
      receiver,
      abi.encodeWithSelector(IOpAdapter.ovmReceive.selector, message),
      SafeCast.toUint32(destinationGasLimit) // for now gas fees are paid on optimism ( < 1.9) and metis (<5M) but its subject to change
    );

    return (OVM_CROSS_DOMAIN_MESSENGER, 0);
  }
}