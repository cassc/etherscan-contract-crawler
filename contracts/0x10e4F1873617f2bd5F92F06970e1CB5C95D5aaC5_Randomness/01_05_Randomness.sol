pragma solidity >=0.4.22 <0.9.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Randomness is VRFConsumerBaseV2, Ownable {
    struct RandomnessRequest {
        uint256[] randomWords;
        bool requested;
        bool fulfilled;
    }

	struct config {
		bytes32 keyHash;
		uint64 subscription;
		uint16 confirmations;
		uint32 gasLimit;
		uint32 numWords;
	}

    event RandomNumberRequested(bytes32 entity, uint256 requestId);
    event RandomNumberGenerated(bytes32 entity, uint256 requestId, uint256[] randomness);

    bytes32 internal _keyHash;
	uint64 internal _subscription;

	config private _defaultConfig;
    mapping(bytes32 => RandomnessRequest) internal _randomRequests;
    mapping(uint256 => bytes32) internal _randomRequestByChainLinkId;

	address internal _vrfCoordinator;

	constructor(address vrfCoordinator_) Ownable() VRFConsumerBaseV2(vrfCoordinator_) {
		_vrfCoordinator = vrfCoordinator_;
	}

	function configure(bytes32 keyHash, uint64 sub, uint16 confirms, uint32 gasLimit, uint32 words) onlyOwner public {
		_defaultConfig = config(
			keyHash,
			sub,
			confirms,
			gasLimit,
			words
		);
	}

	function setDefaults(bytes32 keyHash_, uint64 sub_, uint16 confirms_, uint32 gasLimit_, uint32 words_) onlyOwner public {
		_defaultConfig = config(
			keyHash_,
			sub_,
			confirms_,
			gasLimit_,
			words_
		);
	}

	function readRandomness(bytes32 entity) public view returns(uint256[] memory randomness) {
		return getRandomness(entity);
	}

	function getRandomness(bytes32 entity) public view returns(uint256[] memory randomness) {
		require(_randomRequests[ entity ].fulfilled, "Randomness not ready");
		return _randomRequests[ entity ].randomWords;
	}

	function getRandomnessByRequestId(uint256 requestId) public view returns(uint256[] memory randomness) {
		require(_randomRequestByChainLinkId[requestId] != 0x0, "Unknown request");
		return getRandomness(_randomRequestByChainLinkId[ requestId ]);
	}

    function requestRandomness(bytes32 entity) onlyOwner public virtual {
        _requestRandomness(
			entity,
			_defaultConfig.keyHash,
			_defaultConfig.subscription,
			_defaultConfig.confirmations,
			_defaultConfig.gasLimit,
			_defaultConfig.numWords
		);

    }

	function requestRandomness(bytes32 entity, bytes32 keyHash, uint64 sub, uint16 confirms, uint32 gasLimit, uint32 words) onlyOwner public {
		_requestRandomness(
			entity,
			keyHash,
			sub,
			confirms,
			gasLimit,
			words
		);
	}

	function _requestRandomness(bytes32 entity, bytes32 keyHash, uint64 sub, uint16 confirms, uint32 gasLimit, uint32 words) internal returns(uint256) {
        require(
			! _randomRequests[ entity ].requested,
			"A random number was already request for the given entity."
		);

		uint256 requestId = VRFCoordinatorV2Interface(_vrfCoordinator).requestRandomWords(
			keyHash,
			sub,
			confirms,
			gasLimit,
			words
		);

        _randomRequests[ entity ].requested = true;
        _randomRequestByChainLinkId[ requestId ] = entity;

        emit RandomNumberRequested(entity, requestId);

		return requestId;
	}

	function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual override {
		bytes32 entity = _randomRequestByChainLinkId[ requestId ];
		_randomRequests[ entity ].fulfilled = true;
		_randomRequests[ entity ].randomWords = randomWords;
		emit RandomNumberGenerated(entity, requestId, randomWords);
	}
}