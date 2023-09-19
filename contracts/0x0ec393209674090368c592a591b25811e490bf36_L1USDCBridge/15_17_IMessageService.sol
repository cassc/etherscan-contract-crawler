// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface IMessageService {
  // @dev we include the message hash to save hashing costs
  event MessageSent(
    address indexed _from,
    address indexed _to,
    uint256 _fee,
    uint256 _value,
    uint256 _nonce,
    bytes _calldata,
    bytes32 _messageHash
  );

  event MessageClaimed(
    address indexed _from,
    address indexed _to,
    uint256 _fee,
    uint256 _value,
    uint256 _nonce,
    bytes _calldata,
    bytes32 _messageHash
  );

  /**
   * @notice Sends a message for transporting from the given chain. Must be called by a developer or another contract
   * @dev This function should be called with a msg.value = _value + _fee. The fee will be paid on the destination chain.
   * @param _to the destination address on the destination chain
   * @param _fee the message service fee on the origin chain
   * @param _calldata the calldata used by the destination message service to call the destination contract
   */
  function sendMessage(
    address _to,
    uint256 _fee,
    bytes calldata _calldata
  ) external payable;

  /**
   * @notice Deliver a message to the destination chain
   * @notice Is called automatically by the operator. Cannot be used by developers
   * @param _from the msg.sender calling the origin message service
   * @param _to the destination address on the destination chain
   * @param _value the value to be transferred
   * @param _fee the message service fee on the origin chain
   * @param _feeRecipient address that will receive the fees
   * @param _calldata the calldata used by the destination message service to call the destination contract
   * @param _nonce message salt
   */
  function claimMessage(
    address _from,
    address _to,
    uint256 _fee,
    uint256 _value,
    address payable _feeRecipient,
    bytes calldata _calldata,
    uint256 _nonce
  ) external;

  /**
   * @notice Returns the original sender of the message on the origin layer
   * @return the original sender of the message on the origin layer
   */
  function sender() external view returns (address);
}