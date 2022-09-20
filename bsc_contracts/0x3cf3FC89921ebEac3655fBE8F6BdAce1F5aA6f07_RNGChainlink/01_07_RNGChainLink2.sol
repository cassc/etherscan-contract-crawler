// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "./IRNG.sol";

contract RNGChainlink is IRNG, VRFConsumerBaseV2, Ownable {
  using SafeCast for uint256;

  event VRFRequested(uint256 indexed requestId, uint256 indexed chainlinkRequestId);

  struct VRFConfig {
        bytes32 keyHash;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint64 subscriptionId;
    }

    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    VRFConfig private vrfConfig;


  /// @dev A counter for the number of requests made used for request ids
  uint32 public requestCount;

  /// @dev A list of random numbers from past requests mapped by request id
  mapping(uint32 => uint256) internal randomNumbers;

  /// @dev A list of blocks to be locked at based on past requests mapped by request id
  mapping(uint32 => uint32) internal requestLockBlock;

  /// @dev A mapping from Chainlink request ids to internal request ids
  mapping(uint256 => uint32) internal chainlinkRequestIds;

  mapping(address => bool) public requesterWhitelist;

  constructor(
        address _vrfCoordinator,
        uint64 _vrfSubscriptionId,
        bytes32 _vrfKeyHash,
        uint32 _vrfCallbackGasLimit,
        uint16 _vrfRequestConfirmations
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfConfig = VRFConfig({
            subscriptionId: _vrfSubscriptionId,
            keyHash: _vrfKeyHash,
            callbackGasLimit: _vrfCallbackGasLimit,
            requestConfirmations: _vrfRequestConfirmations
        });
    }

    /// @notice Configure `requester` for whitelist
    function allowRequestsFrom(address requester, bool allow) external onlyOwner {
      requesterWhitelist[requester] = allow;
    }

    /// @notice Change Chainlink VRF V2 configuration
    function configureVRF(
        uint64 _vrfSubscriptionId,
        bytes32 _vrfKeyHash,
        uint16 _vrfRequestConfirmations,
        uint32 _vrfCallbackGasLimit
    ) external onlyOwner {
        VRFConfig storage vrf = vrfConfig;
        vrf.subscriptionId = _vrfSubscriptionId;
        vrf.keyHash = _vrfKeyHash;
        vrf.requestConfirmations = _vrfRequestConfirmations;
        vrf.callbackGasLimit = _vrfCallbackGasLimit;
    }

  /// @notice Gets the last request id used by the RNG service
  /// @return requestId The last request id used in the last request
  function getLastRequestId() external override view returns (uint32 requestId) {
    return requestCount;
  }

  /// @notice Gets the Fee for making a Request against an RNG service
  /// @return feeToken The address of the token that is used to pay fees
  /// @return requestFee The fee required to be paid to make a request
  // solhint-disable-next-line pure
  function getRequestFee() external override pure returns (address feeToken, uint256 requestFee) { 
    return (address(0), 0);
  }

  /// @notice Sends a request for a random number to the 3rd-party service
  /// @dev Some services will complete the request immediately, others may have a time-delay
  /// @dev Some services require payment in the form of a token, such as $LINK for Chainlink VRF
  /// @return requestId The ID of the request used to get the results of the RNG service
  /// @return lockBlock The block number at which the RNG service will start generating time-delayed randomness.  The calling contract
  /// should "lock" all activity until the result is available via the `requestId`
  function requestRandomNumber() external override returns (uint32 requestId, uint32 lockBlock) {
    uint256 seed = _getSeed();
    lockBlock = uint32(block.number);

    require(requesterWhitelist[msg.sender], "Not allowed to request RNG");
    requestId = _requestRandomness(seed);

    requestLockBlock[requestId] = lockBlock;

    emit RandomNumberRequested(requestId, msg.sender);
  }

  /// @notice Checks if the request for randomness from the 3rd-party service has completed
  /// @dev For time-delayed requests, this function is used to check/confirm completion
  /// @param requestId The ID of the request used to get the results of the RNG service
  /// @return isCompleted True if the request has completed and a random number is available, false otherwise
  function isRequestComplete(uint32 requestId) external override view returns (bool isCompleted) {
    return randomNumbers[requestId] != 0;
  }

  /// @notice Gets the random number produced by the 3rd-party service
  /// @param requestId The ID of the request used to get the results of the RNG service
  /// @return randomNum The random number
  function randomNumber(uint32 requestId) external view override returns (uint256 randomNum) {
    return randomNumbers[requestId];
  }

  /// @dev Requests a new random number from the Chainlink VRF
  /// @dev The result of the request is returned in the function `fulfillRandomness`
  function _requestRandomness(uint256) internal returns (uint32 requestId) {
    // Get next request ID
    requestId = _getNextRequestId();

    // Complete request
    VRFConfig memory vrf = vrfConfig;
    uint256 vrfRequestId = vrfCoordinator.requestRandomWords(
			vrf.keyHash,
			vrf.subscriptionId,
			vrf.requestConfirmations,
			vrf.callbackGasLimit,
			1
		);

    chainlinkRequestIds[vrfRequestId] = requestId;

    emit VRFRequested(requestId, vrfRequestId);
  }

  /// @notice Callback function used by VRF Coordinator
  /// @dev The VRF Coordinator will only send this function verified responses.
  /// @dev The VRF Coordinator will not pass randomness that could not be verified.
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override {
    uint32 internalRequestId = chainlinkRequestIds[requestId];

    // Store random value
    randomNumbers[internalRequestId] = randomWords[0];

    emit RandomNumberCompleted(internalRequestId, randomWords[0]);
  }

  /// @dev Gets the next consecutive request ID to be used
  /// @return requestId The ID to be used for the next request
  function _getNextRequestId() internal returns (uint32 requestId) {
    requestCount = (uint256(requestCount) + 1).toUint32();
    requestId = requestCount;
  }

  /// @dev Gets a seed for a random number from the latest available blockhash
  /// @return seed The seed to be used for generating a random number
  function _getSeed() internal virtual view returns (uint256 seed) {
    return uint256(blockhash(block.number - 1));
  }
}