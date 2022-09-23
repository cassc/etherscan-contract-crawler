pragma solidity ^0.8.2;

import "IVRFCoordinatorV2Interface.sol";
import "ILink.sol";
import "Ownable.sol";

abstract contract VRFConsumerBaseV2 is Ownable {

	struct RequestConfig {
		uint64 subId;
		uint32 callbackGasLimit;
		uint16 requestConfirmations;
		uint32 numWords;
		bytes32 keyHash;
	}

	RequestConfig public config;
	IVRFCoordinatorV2Interface private COORDINATOR;
	LinkTokenInterface private LINK;


	/**
	* @param _vrfCoordinator address of VRFCoordinator contract
	*/
	// mainnet coord: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
	// mainnet link:  0x514910771af9ca656af840dff83e8264ecf986ca
	constructor(address _vrfCoordinator, address _link) {
		COORDINATOR = IVRFCoordinatorV2Interface(_vrfCoordinator);
		LINK = LinkTokenInterface(_link);
		
		config = RequestConfig({
			subId: 0,
			callbackGasLimit: 1000000,
			requestConfirmations: 3,
			numWords: 1,
			keyHash: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef
		});
	}

	function setupConfig(uint32 _gasLimit, uint16 _requestConfirmations, uint32 _numWords, bytes32 _keyHash) external onlyOwner {
		uint64 _subId = config.subId;
		config = RequestConfig({
			subId: _subId,
			callbackGasLimit: _gasLimit,
			requestConfirmations: _requestConfirmations,
			numWords: _numWords,
			keyHash: _keyHash
		});
	}

	/**
	* @notice fulfillRandomness handles the VRF response. Your contract must
	* @notice implement it. See "SECURITY CONSIDERATIONS" above for important
	* @notice principles to keep in mind when implementing your fulfillRandomness
	* @notice method.
	*
	* @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
	* @dev signature, and will call it once it has verified the proof
	* @dev associated with the randomness. (It is triggered via a call to
	* @dev rawFulfillRandomness, below.)
	*
	* @param requestId The Id initially returned by requestRandomness
	* @param randomWords the VRF output expanded to the requested number of words
	*/
	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

	// rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
	// proof. rawFulfillRandomness then calls fulfillRandomness, after validating
	// the origin of the call
	function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
		require (msg.sender == address(COORDINATOR), "!coordinator");
		fulfillRandomWords(requestId, randomWords);
	}

	  // Assumes the subscription is funded sufficiently.
	function requestRandomWords() internal returns(uint256 requestId) {
		RequestConfig memory rc = config;
		// Will revert if subscription is not set and funded.
		requestId = COORDINATOR.requestRandomWords(
			rc.keyHash,
			rc.subId,
			rc.requestConfirmations,
			rc.callbackGasLimit,
			rc.numWords
		);
	}

	function topUpSubscription(uint256 amount) external onlyOwner {
		LINK.transferAndCall(address(COORDINATOR), amount, abi.encode(config.subId));
	}

	function withdraw(uint256 amount, address to) external onlyOwner {
		LINK.transfer(to, amount);
	}

	function unsubscribe(address to) external onlyOwner {
		// Returns funds to this address
		COORDINATOR.cancelSubscription(config.subId, to);
		config.subId = 0;
	}

	function subscribe() public onlyOwner {
		// Create a subscription, current subId
		address[] memory consumers = new address[](1);
		consumers[0] = address(this);
		config.subId = COORDINATOR.createSubscription();
		COORDINATOR.addConsumer(config.subId, consumers[0]);
	}
}