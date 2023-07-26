// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/vrf/VRFConsumerBaseV2.sol";

// import {AutomationCompatibleInterface} from "@chainlink/interfaces/automation/AutomationCompatibleInterface.sol";

/* Enums */
enum RequestType {
    None,
    Raffle,
    XCrate
}

/**@title A sample VRF Contract
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */
abstract contract XKeyVRFInterface is VRFConsumerBaseV2 {
    /* Errors */
    error AlreadyRequested();
    error InvalidVRFRequestType();

    /* Events */
    // event VRFRequest(uint256 indexed requestId, RequestType indexed _type);

    /* State variables */
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    uint64 private immutable vrfSubscriptionId;
    address private immutable vrfV2CoordinatorAddress;
    bytes32 private immutable gasLane;

    /* VRF config constants */
    uint32 private constant CALLBACK_GAS_LIMIT = 500000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // current request for a winner for a round
    uint8 public awaitingWinnerForRound;

    // current request for a winner for a crate
    uint16 public awaitingWinnerForCrate;

    mapping(uint256 => RequestType) internal vrfRequests;
    mapping(uint256 requestId => uint16 crateId) internal vrfIdToCrateId;

    /* Functions */
    constructor(
        address _vrfCoordinator,
        uint64 _vrfSubscriptionId,
        bytes32 _gasLane
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        // initialize Chainlink VRF
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);

        // initialize immutable variables
        vrfV2CoordinatorAddress = _vrfCoordinator;
        vrfSubscriptionId = _vrfSubscriptionId;
        gasLane = _gasLane;
    }

    function sendVRFRequest() internal returns (uint256) {
        uint256 requestId = vrfCoordinator.requestRandomWords(
            gasLane,
            vrfSubscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        // @todo comment out for mainnet;
        // only needed for VRFCoordinatorV2Mock in unit tests
        // pendingRequestId = requestId;

        return requestId;
    }

    function _placeRequestInternal(RequestType _type) internal returns (uint256) {
        uint256 requestId = sendVRFRequest();

        // set the request type
        vrfRequests[requestId] = _type;

        // emit VRFRequest(requestId, _type);

        return requestId;
    }

    function requestWinningTokenForRound(uint8 round) internal {
        if (awaitingWinnerForRound != 0) {
            revert AlreadyRequested();
        }
        awaitingWinnerForRound = round;

        _placeRequestInternal(RequestType.Raffle);
    }

    function requestWinnerForCrate(uint16 crateId) internal {
        if (awaitingWinnerForCrate != 0) {
            revert AlreadyRequested();
        }
        awaitingWinnerForCrate = crateId;

        uint256 requestId = _placeRequestInternal(RequestType.XCrate);

        // record the crateId for the requestId
        vrfIdToCrateId[requestId] = crateId;
    }
}