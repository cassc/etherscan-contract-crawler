// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IBaseAdapter
 * @author BGD Labs
 * @notice interface containing the event and method used in all bridge adapters
 */
interface IBaseAdapter {
  /**
   * @notice emitted when a trusted remote is set
   * @param originChainId id of the chain where the trusted remote is from
   * @param originForwarder address of the contract that will send the messages
   */
  event SetTrustedRemote(uint256 originChainId, address originForwarder);

  /**
   * @notice pair of origin address and origin chain
   * @param originForwarder address of the contract that will send the messages
   * @param originChainId id of the chain where the trusted remote is from
   */
  struct TrustedRemotesConfig {
    address originForwarder;
    uint256 originChainId;
  }

  /**
   * @notice method that will bridge the payload to the chain specified
   * @param receiver address of the receiver contract on destination chain
   * @param gasLimit amount of the gas limit in wei to use for bridging on receiver side. Each adapter will manage this
            as needed
   * @param destinationChainId id of the destination chain in the bridge notation
   * @param message to send to the specified chain
   * @return the third-party bridge entrypoint, the third-party bridge message id
   */
  function forwardMessage(
    address receiver,
    uint256 gasLimit,
    uint256 destinationChainId,
    bytes calldata message
  ) external returns (address, uint256);

  /**
   * @notice method used to setup payment, ie grant approvals over tokens used to pay for tx fees
   */
  function setupPayments() external;

  /**
   * @notice method to get the trusted remote address from a specified chain id
   * @param chainId id of the chain from where to get the trusted remote
   * @return address of the trusted remote
   */
  function getTrustedRemoteByChainId(uint256 chainId) external view returns (address);

  /**
   * @notice method to get infrastructure chain id from bridge native chain id
   * @param bridgeChainId bridge native chain id
   */
  function nativeToInfraChainId(uint256 bridgeChainId) external returns (uint256);

  /**
   * @notice method to get bridge native chain id from native bridge chain id
   * @param infraChainId infrastructure chain id
   */
  function infraToNativeChainId(uint256 infraChainId) external returns (uint256);
}