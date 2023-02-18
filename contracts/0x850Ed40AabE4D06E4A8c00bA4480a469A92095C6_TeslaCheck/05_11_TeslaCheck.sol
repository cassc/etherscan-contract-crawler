// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./Token.sol";

struct PendingResult {
    address owner;
    uint16 random;
    bool received;
}

struct VrfConfig {
    address requestAddress;
    bytes32 keyHash;
    uint64 subId;
    uint16 confirmations;
    uint32 callbackGasLimit;
    uint32 numWords;
}

struct RequestStatus {
    uint16 processedCount;
    uint16 pendingToken;
    uint128 lastRequestAt;
}

contract TeslaCheck is VRFConsumerBaseV2, Ownable {
    address public NftAddress;
    VrfConfig public vrf;
    uint256 public startingTokenCount = 1200;

    uint256 public burningStartsAt;
    uint256 public burningEndsAt;
    bool public paused = false;

    uint256 public minRequestInterval = 10 minutes; // 10 * 60; // 600 seconds, 10 minutes

    RequestStatus public requestStatus;
    uint256 public winningToken = 9999;

    mapping(uint256 => PendingResult) public pendingRequests;

    event EntrySubmitted(
        address indexed operator,
        uint256 indexed token,
        uint256 indexed randomRequestId
    );
    event EntryProcessed(
        uint256 indexed token,
        uint256 indexed random,
        uint256 indexed tokensRemaining
    );
    event Winner(address indexed winner, uint256 indexed tokenID);
    event ResubmitRandom(
        uint256 indexed requesetId,
        uint256 indexed tokenID,
        uint256 indexed randomValue
    );
    event ConfigUpdated(address indexed operator, uint256 indexed timestamp);
    event Paused(address indexed operator, bool indexed isPaused);

    modifier unpaused() {
        require(!paused, "paused");
        _;
    }

    constructor(address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {
        requestStatus.pendingToken = 9999;
    }

    function config(
        address tokenAddress,
        uint256 startTs,
        uint256 endTs,
        uint256 minInterval,
        uint256 startingCount,
        VrfConfig memory v
    ) public onlyOwner {
        NftAddress = tokenAddress;
        burningStartsAt = startTs;
        burningEndsAt = endTs;
        minRequestInterval = minInterval;
        startingTokenCount = startingCount;
        vrf = v;
        emit ConfigUpdated(msg.sender, block.timestamp);
    }

    function setPaused(bool p) public onlyOwner {
        paused = p;
        emit Paused(msg.sender, p);
    }

    function resubmitRandom(
        uint256 token,
        uint256 requestId,
        uint256[] memory randomWords
    ) public onlyOwner {
        require(
            token == uint256(requestStatus.pendingToken),
            "can not submit random result for non-pending token"
        );
        processRandom(token, randomWords[0]);
    }

    function burn(uint256 token) public unpaused {
        require(
            isOwnerOrApprovedForToken(msg.sender, token),
            "you're not authorized to burn this token"
        );
        require(
            requestStatus.lastRequestAt <
                uint128(block.timestamp) - uint128(minRequestInterval),
            "can not burn yet"
        );
        require(
            requestStatus.pendingToken == 9999,
            "missing result from previous request"
        );
        require(winningToken == 9999, "winner has already been declared");
        require(block.timestamp > burningStartsAt, "burning is not open");
        require(block.timestamp <= burningEndsAt, "burning is closed");
        require(
            pendingRequests[token].owner == address(0),
            "token already burned"
        );

        requestStatus.lastRequestAt = uint128(block.timestamp);
        Token(NftAddress).burn(token);
        uint256 requestID = requestRandom();
        requestStatus.pendingToken = uint16(token);
        pendingRequests[token] = PendingResult(msg.sender, 0, false);

        emit EntrySubmitted(msg.sender, token, requestID);
    }

    function isOwnerOrApprovedForToken(address operator, uint256 token)
        internal
        view
        returns (bool)
    {
        Token t = Token(NftAddress);
        address owner = t.ownerOf(token);

        if (owner == operator) {
            return true;
        }

        if (t.isApprovedForAll(owner, operator)) {
            return true;
        }

        if (t.getApproved(token) == operator) {
            return true;
        }

        return false;
    }

    function requestRandom() internal returns (uint256) {
        uint256 requestID = VRFCoordinatorV2Interface(vrf.requestAddress)
            .requestRandomWords(
                vrf.keyHash,
                vrf.subId,
                vrf.confirmations,
                vrf.callbackGasLimit,
                vrf.numWords
            );

        return requestID;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual
        override
    {
        require(
            requestStatus.pendingToken != 9999,
            "unexpected random request"
        );
        processRandom(requestStatus.pendingToken, randomWords[0]);
    }

    function processRandom(uint256 token, uint256 random) internal {
        require(
            pendingRequests[token].owner != address(0) &&
                pendingRequests[token].received == false,
            "unexpected random response"
        );

        pendingRequests[token].received = true;

        emit EntryProcessed(
            token,
            random,
            startingTokenCount - uint256(requestStatus.processedCount)
        );

        if (isWinnable(random)) {
            if (winningToken == 9999) {
                winningToken = uint16(token);
                emit Winner(pendingRequests[token].owner, token);
            }
        }

        pendingRequests[token].random = uint16(
            random %
                (startingTokenCount - uint256(requestStatus.processedCount))
        );
        requestStatus.pendingToken = 9999;
        requestStatus.processedCount++;
    }

    function isWinnable(uint256 random) internal view returns (bool) {
        if (random % (startingTokenCount - requestStatus.processedCount) != 0) {
            return false;
        }

        return true;
    }

    function getWinningToken() public view returns (bool, uint256) {
        return (winningToken != 9999, uint256(winningToken));
    }

    function getTokenRequest(uint256 token)
        public
        view
        returns (bool, PendingResult memory)
    {
        return (
            pendingRequests[token].owner != address(0),
            pendingRequests[token]
        );
    }

    function canSubmitAt() public view returns (bool, uint64) {
        if (requestStatus.pendingToken != 9999) {
            return (false, 0);
        }

        bool canSubmit = block.timestamp >
            requestStatus.lastRequestAt + minRequestInterval;

        return (
            canSubmit,
            uint64(requestStatus.lastRequestAt + minRequestInterval)
        );
    }
}

interface IBurn {
    event EntrySubmitted(
        address indexed operator,
        uint256 indexed token,
        uint256 indexed randomRequestId
    );
    event EntryProcessed(
        uint256 indexed token,
        uint256 indexed random,
        uint256 indexed tokensRemaining
    );
    event Winner(address indexed winner, uint256 indexed tokenID);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event RandomWordsRequested(
        bytes32 indexed keyHash,
        uint256 requestId,
        uint256 preSeed,
        uint64 indexed subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        address indexed sender
    );

    function burn(uint256 token) external;

    function canSubmitAt() external view returns (bool, uint64);
}