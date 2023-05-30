// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract VRFv2Consumer is VRFConsumerBaseV2 {
	event RequestSent(uint256 requestId, uint32 numWords);
	event RequestFulfilled(uint256 requestId, uint256[] randomWords);

	struct RequestStatus {
		bool fulfilled; // whether the request has been successfully fulfilled
		bool exists; // whether a requestId exists
		uint256[] randomWords;
	}
	mapping(uint256 => RequestStatus)
		public s_requests; /* requestId --> requestStatus */
	VRFCoordinatorV2Interface COORDINATOR;

	// Your subscription ID.
	uint64 s_subscriptionId;

	// past requests Id.
	uint256[] public requestIds;
	uint256 public lastRequestId;
	uint256 public entropy;

	// The gas lane to use, which specifies the maximum gas price to bump to.
	// For a list of available gas lanes on each network,
	// see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
	bytes32 keyHash =
		0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

	// Depends on the number of requested values that you want sent to the
	// fulfillRandomWords() function. Storing each word costs about 20,000 gas,
	// so 100,000 is a safe default for this example contract. Test and adjust
	// this limit based on the network that you select, the size of the request,
	// and the processing of the callback request in the fulfillRandomWords()
	// function.
	uint32 callbackGasLimit = 100000;

	// The default is 3, but you can set this higher.
	uint16 requestConfirmations = 3;

	// For this example, retrieve 2 random values in one request.
	// Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
	uint32 numWords = 1;

	/**
	 * HARDCODED FOR GOERLI
	 * COORDINATOR: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
	 */
	constructor(
		uint64 subscriptionId
	)
		VRFConsumerBaseV2(0x271682DEB8C4E0901D1a1550aD2e64D568E69909)
	{
		COORDINATOR = VRFCoordinatorV2Interface(
			0x271682DEB8C4E0901D1a1550aD2e64D568E69909
		);
		s_subscriptionId = subscriptionId;
	}

	// Assumes the subscription is funded sufficiently.
	function requestRandomWords() internal returns (uint256 requestId) {
		// Will revert if subscription is not set and funded.
		requestId = COORDINATOR.requestRandomWords(
			keyHash,
			s_subscriptionId,
			requestConfirmations,
			callbackGasLimit,
			numWords
		);
		s_requests[requestId] = RequestStatus({
			randomWords: new uint256[](0),
			exists: true,
			fulfilled: false
		});
		requestIds.push(requestId);
		lastRequestId = requestId;
		emit RequestSent(requestId, numWords);
		return requestId;
	}

	function fulfillRandomWords(
		uint256 _requestId,
		uint256[] memory _randomWords
	) internal override {
		require(s_requests[_requestId].exists, "request not found");
		s_requests[_requestId].fulfilled = true;
		s_requests[_requestId].randomWords = _randomWords;
		entropy = _randomWords[0];
		emit RequestFulfilled(_requestId, _randomWords);
	}

	function getRequestStatus(
		uint256 _requestId
	) external view returns (bool fulfilled, uint256[] memory randomWords) {
		require(s_requests[_requestId].exists, "request not found");
		RequestStatus memory request = s_requests[_requestId];
		return (request.fulfilled, request.randomWords);
	}
}