// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IArbAdapter
 * @author BGD Labs
 * @notice interface containing the events, objects and method definitions used in the Arbitrum bridge adapter
 */
interface IArbAdapter {
  /**
   * @notice object used to store the message information
   * @param receiver address that will receive the message
   * @param destinationGasLimit max gas limit to be used on destination chain
   * @param maxSubmission gas required for ticket submission
   * @param maxRedemption gas required for ticket redemption
   * @param encodedMessage calldata used on destination chain
   */
  struct MessageInformation {
    address receiver;
    uint256 destinationGasLimit;
    uint256 maxSubmission;
    uint256 maxRedemption;
    bytes encodedMessage;
  }

  /**
   * @notice method to get the INBOX address
   * @return address of the INBOX
   */
  function INBOX() external view returns (address);

  /**
   * @notice method to get the destination CrossChainController
   * @return address of the dstination CrossChainController
   */
  function DESTINATION_CCC() external view returns (address);

  /**
   * @notice amount of gwei to overpay on basefee for fast submission
   * @return fee margin in gwei
   */
  function BASE_FEE_MARGIN() external view returns (uint256);

  /**
   * @notice method to get the max fee per gas on destination chain
   * @return max fee per gas
   * @dev There is currently no oracle on L1 exposing gasPrice of arbitrum.
          Therefore we overpay by assuming 1 gwei (10x of current price).
   */
  function L2_MAX_FEE_PER_GAS() external view returns (uint256);

  /**
   * @notice method to know if a destination chain is supported
   * @return flag indicating if the destination chain is supported
   */
  function isDestinationChainIdSupported(uint256 chainId) external view returns (bool);

  /**
   * @notice method to get the origin chain id
   * @return id of the chain where the messages originate.
   * @dev this method is needed as Arbitrum does not pass the origin chain
   */
  function getOriginChainId() external view returns (uint256);

  /**
   * @notice method called by arbitrum with the bridged message
   * @param message bytes containing the bridged information
   */
  function arbReceive(bytes memory message) external;

  /**
   * @dev returns the amount of gas needed for submitting the ticket
   * @param bytesLength the payload bytes length (usually 580)
   * @param gasLimit max number of gas to be used
   * @return uint256 maxSubmissionFee needed on L2 with BASE_FEE_MARGIN
   * @return uint256 estimated L2 redepmption fee
   */
  function getRequiredGas(
    uint256 bytesLength,
    uint256 gasLimit
  ) external view returns (uint256, uint256);
}