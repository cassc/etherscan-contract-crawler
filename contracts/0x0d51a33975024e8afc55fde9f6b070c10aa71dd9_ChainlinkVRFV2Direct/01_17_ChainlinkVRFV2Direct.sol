// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { VRFV2WrapperConsumerBase } from "chainlink/vrf/VRFV2WrapperConsumerBase.sol";
import { Ownable } from "owner-manager/Ownable.sol";

import { VRFV2Wrapper } from "chainlink/vrf/VRFV2Wrapper.sol";
import { LinkTokenInterface } from "chainlink/interfaces/LinkTokenInterface.sol";
import { RNGInterface } from "rng-contracts/RNGInterface.sol";

contract ChainlinkVRFV2Direct is VRFV2WrapperConsumerBase, Ownable, RNGInterface {

  /* ============ Global Variables ============ */

  /// @notice A counter for the number of requests made used for request ids
  uint32 internal _requestCounter;

  /// @notice The callback gas limit
  uint32 internal _callbackGasLimit;

  /// @notice The number of confirmations to wait before fulfilling the request
  uint16 internal _requestConfirmations;

  /// @notice A list of random numbers from past requests mapped by request id
  mapping(uint32 => uint256) internal _randomNumbers;

  /// @notice A list of random number completion timestamps mapped by request id
  mapping(uint32 => uint64) internal _requestCompletedAt;

  /// @notice A mapping from Chainlink request ids to internal request ids
  mapping(uint256 => uint32) internal _chainlinkRequestIds;

  /* ============ Custom Errors ============ */

  /// @notice Thrown when the LINK token contract address is set to the zero address.
  error LinkTokenZeroAddress();

  /// @notice Thrown when the VRFV2Wrapper address is set to the zero address.
  error VRFV2WrapperZeroAddress();

  /// @notice Thrown when the callback gas limit is set to zero.
  error CallbackGasLimitZero();

  /// @notice Thrown when the number of request confirmations is set to zero.
  error RequestConfirmationsZero();

  /// @notice Thrown when the chainlink VRF request ID does not match any stored request IDs.
  /// @param vrfRequestId The chainlink ID for the VRF Request
  error InvalidVrfRequestId(uint256 vrfRequestId);

  /* ============ Custom Events ============ */

  /// @notice Emitted when the callback gas limit is set
  /// @param callbackGasLimit The new callback gas limit
  event SetCallbackGasLimit(uint32 callbackGasLimit);

  /// @notice Emitted when the number of request confirmations is set.
  /// @param requestConfirmations The new request confirmations
  event SetRequestConfirmations(uint16 requestConfirmations);

  /* ============ Constructor ============ */

  /**
   * @notice Constructor of the contract
   * @param _owner Address of the contract owner
   * @param _vrfV2Wrapper Address of the VRF V2 Wrapper
   * @param callbackGasLimit_ Gas limit for the fulfillRandomWords callback
   * @param requestConfirmations_ The number of confirmations to wait before fulfilling the request
   */
  constructor(
    address _owner,
    VRFV2Wrapper _vrfV2Wrapper,
    uint32 callbackGasLimit_,
    uint16 requestConfirmations_
  ) VRFV2WrapperConsumerBase(address(_vrfV2Wrapper.LINK()), address(_vrfV2Wrapper)) Ownable(_owner) {
    if (address(_vrfV2Wrapper) == address(0)) revert VRFV2WrapperZeroAddress();
    _setCallbackGasLimit(callbackGasLimit_);
    _setRequestConfirmations(requestConfirmations_);
  }

  /* ============ External Functions ============ */

  /// @inheritdoc RNGInterface
  function requestRandomNumber()
    external
    returns (uint32 requestId, uint32 lockBlock)
  {
    uint256 _vrfRequestId = requestRandomness(
      _callbackGasLimit, // TODO: make callback gas updateable or configurable by caller
      _requestConfirmations,
      1 // num words
    );

    _requestCounter = _requestCounter + 1;

    requestId = _requestCounter;
    _chainlinkRequestIds[_vrfRequestId] = _requestCounter;

    lockBlock = uint32(block.number);

    emit RandomNumberRequested(_requestCounter, msg.sender);
  }

  /// @inheritdoc RNGInterface
  function isRequestComplete(uint32 _internalRequestId)
    external
    view
    override
    returns (bool isCompleted)
  {
    return _randomNumbers[_internalRequestId] != 0;
  }

  /// @inheritdoc RNGInterface
  function randomNumber(uint32 _internalRequestId)
    external
    view
    override
    returns (uint256 randomNum)
  {
    return _randomNumbers[_internalRequestId];
  }

  /**
   * @notice Returns the timestamp at which the passed `requestId` was completed.
   * @dev Returns zero if not completed or if the request doesn't exist
   * @param requestId The ID of the request
   */
  function completedAt(uint32 requestId) external view returns (uint64 completedAtTimestamp) {
    return _requestCompletedAt[requestId];
  }

  /// @inheritdoc RNGInterface
  function getLastRequestId() external view override returns (uint32 requestId) {
    return _requestCounter;
  }

  /// @inheritdoc RNGInterface
  function getRequestFee() external view override returns (address feeToken, uint256 requestFee) {
    return (address(LINK), VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit));
  }

  /// @notice Returns the current callback gas limit.
  /// @return The current callback gas limit
  function getCallbackGasLimit() external view returns (uint32) {
    return _callbackGasLimit;
  }

  /// @notice Returns the current request confirmation count.
  /// @return The current request confirmation count
  function getRequestConfirmations() external view returns (uint16) {
    return _requestConfirmations;
  }

  /// @notice Returns the VRF V2 Wrapper contract that this contract uses.
  /// @return The VRFV2Wrapper contract
  function vrfV2Wrapper() external view returns (VRFV2Wrapper) {
    return VRFV2Wrapper(address(VRF_V2_WRAPPER));
  }

  /* ============ External Setters ============ */

  /// @notice Sets a new callback gat limit.
  /// @param callbackGasLimit_ The new callback gat limit
  function setCallbackGasLimit(uint32 callbackGasLimit_) external onlyOwner {
    _setCallbackGasLimit(callbackGasLimit_);
  }

  /// @notice Sets a new request confirmation count.
  /// @param requestConfirmations_ The new request confirmation count
  function setRequestConfirmations(uint16 requestConfirmations_) external onlyOwner {
    _setRequestConfirmations(requestConfirmations_);
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Callback function called by VRF Wrapper
   * @dev The VRF Wrapper will only call it once it has verified the proof associated with the randomness.
   * @param _vrfRequestId Chainlink VRF request id
   * @param _randomWords Chainlink VRF array of random words
   */
  function fulfillRandomWords(uint256 _vrfRequestId, uint256[] memory _randomWords)
    internal
    override
  {
    uint32 _internalRequestId = _chainlinkRequestIds[_vrfRequestId];
    if (_internalRequestId == 0) revert InvalidVrfRequestId(_vrfRequestId);

    uint256 _randomNumber = _randomWords[0];
    _randomNumbers[_internalRequestId] = _randomNumber;
    _requestCompletedAt[_internalRequestId] = uint64(block.timestamp);

    emit RandomNumberCompleted(_internalRequestId, _randomNumber);
  }

  /* ============ Internal Setters ============ */

  /// @notice Sets a new callback gat limit.
  /// @param callbackGasLimit_ The new callback gat limit
  function _setCallbackGasLimit(uint32 callbackGasLimit_) internal {
    if (callbackGasLimit_ == 0) revert CallbackGasLimitZero();
    _callbackGasLimit = callbackGasLimit_;
    emit SetCallbackGasLimit(_callbackGasLimit);
  }

  /// @notice Sets a new request confirmation count.
  /// @param requestConfirmations_ The new request confirmation count
  function _setRequestConfirmations(uint16 requestConfirmations_) internal {
    if (requestConfirmations_ == 0) revert RequestConfirmationsZero();
    _requestConfirmations = requestConfirmations_;
    emit SetRequestConfirmations(_requestConfirmations);
  }

}