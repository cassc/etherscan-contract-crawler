// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import 'chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import 'chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol';
import 'chainlink/contracts/src/v0.8/ConfirmedOwner.sol';

contract TallyVrfV1 is VRFConsumerBaseV2, ConfirmedOwner {
  /// @notice Emitted when a request is sent to the VRF Coordinator
  event RequestSent(uint256 requestId, uint32 wordCount, string message);
  /// @notice Emitted when a request is fulfilled by the VRF Coordinator
  event RequestFulfilled(
    uint256 requestId,
    uint256[] randomWords,
    uint256[] ranges,
    uint256[] startingIndices,
    uint256[] randomIndices,
    string message
  );

  /// @notice Records the details of a VRF request
  struct RequestDetail {
    bool fulfilled;
    bool exists;
    uint256[] ranges;
    uint256[] startingIndices;
    uint256[] randomWords;
    uint256[] randomIndices;
    string message;
  }

  /// @notice Mapping of request IDs to their corresponding request details
  mapping(uint256 => RequestDetail) public requests;

  /// @notice The VRF Coordinator contract
  VRFCoordinatorV2Interface public immutable COORDINATOR;

  /// @notice List of all request IDs
  uint256[] public requestIds;
  /// @notice The most recent request ID
  uint256 public lastRequestId;

  /// @notice VRF parameters
  struct VrfParams {
    uint64 subscriptionId;
    bytes32 keyHash; // Gas lane for max gas price
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    uint32 wordCount; // Number of random words to request (max 500)
    uint256[] ranges; // List of range lengths for random numbers
    uint256[] startingIndices; // List of starting indices for each range
  }

  /// @notice Instantiation of VRF parameters
  VrfParams public params;

  constructor(
    address _vrfCoordinator
  ) VRFConsumerBaseV2(_vrfCoordinator) ConfirmedOwner(msg.sender) {
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
  }

  /// @notice Request random words from the VRF Coordinator
  function requestRandomWords(
    string memory _message
  ) external onlyOwner returns (uint256 requestId) {
    VrfParams memory _params = params;
    requestId = COORDINATOR.requestRandomWords(
      _params.keyHash,
      _params.subscriptionId,
      _params.requestConfirmations,
      _params.callbackGasLimit,
      _params.wordCount
    );
    requests[requestId] = RequestDetail({
      randomWords: new uint256[](0),
      randomIndices: new uint256[](0),
      ranges: _params.ranges,
      startingIndices: _params.startingIndices,
      exists: true,
      fulfilled: false,
      message: _message
    });
    requestIds.push(requestId);
    lastRequestId = requestId;
    emit RequestSent(requestId, _params.wordCount, _message);
    return requestId;
  }

  /// @notice Callback function used by the VRF Coordinator
  function fulfillRandomWords(
    uint256 _requestId,
    uint256[] memory _randomWords
  ) internal override {
    require(requests[_requestId].exists, 'request not found');
    requests[_requestId].fulfilled = true;
    requests[_requestId].randomWords = _randomWords;

    uint256[] memory _ranges = requests[_requestId].ranges;
    uint256[] memory _startingIndices = requests[_requestId].startingIndices;
    string memory _message = requests[_requestId].message;

    if (_ranges.length < 1) {
      emit RequestFulfilled(
        _requestId,
        _randomWords,
        _ranges,
        _startingIndices,
        requests[_requestId].randomIndices,
        _message
      );
      return;
    }

    uint256[] memory _randomIndices = new uint256[](_randomWords.length);

    for (uint256 i = 0; i < _randomWords.length; ++i) {
      uint256 _randomIndex = (_randomWords[i] % _ranges[i]) + _startingIndices[i];
      _randomIndices[i] = _randomIndex;
    }
    requests[_requestId].randomIndices = _randomIndices;

    emit RequestFulfilled(
      _requestId,
      _randomWords,
      _ranges,
      _startingIndices,
      _randomIndices,
      _message
    );
  }

  /// @notice Get the details of a specific request
  function getRequestDetails(
    uint256 _requestId
  )
    external
    view
    returns (
      bool fulfilled,
      uint256[] memory ranges,
      uint256[] memory startingIndices,
      uint256[] memory randomWords,
      uint256[] memory randomIndices,
      string memory message
    )
  {
    require(requests[_requestId].exists, 'request not found');
    RequestDetail memory request = requests[_requestId];
    return (
      request.fulfilled,
      request.ranges,
      request.startingIndices,
      request.randomWords,
      request.randomIndices,
      request.message
    );
  }

  /// @notice Set VRF parameters
  function setVrfStruct(VrfParams calldata _params) external onlyOwner {
    require(
      _params.ranges.length == _params.startingIndices.length,
      'mismatched arrays'
    );
    require(
      _params.ranges.length == 0 || _params.wordCount == _params.ranges.length,
      'invalid arrays'
    );
    params = VrfParams({
      subscriptionId: _params.subscriptionId,
      keyHash: _params.keyHash,
      callbackGasLimit: _params.callbackGasLimit,
      requestConfirmations: _params.requestConfirmations,
      wordCount: _params.wordCount,
      ranges: _params.ranges,
      startingIndices: _params.startingIndices
    });
  }
}