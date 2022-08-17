pragma solidity 0.8.7;
// SPDX-License-Identifier: MIT

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title Random Number Integer Generator Contract
 * @notice This contract fetches verified random numbers which can then be used offchain
 */


/**
* @dev Data required to create the random number for a given VFR request
*/
struct RandomNumberRequested {
    uint minValue; // minimum value of the random number (inclusive)
    uint maxValue; // maximum value of the random number (inclusive)
    string title; // reason for the random number request
    uint randomWords; // response value from VRF
    uint randomNumber; // final random number result
}

contract RandomNumberEchelon is VRFConsumerBaseV2, Ownable {
    // Chainlink Parameters
    VRFCoordinatorV2Interface internal COORDINATOR;

    uint64 internal s_subscriptionId = 294;
    address internal vrfCoordinator =
    0x271682DEB8C4E0901D1a1550aD2e64D568E69909;  // mainnet
    address internal link = 0x514910771AF9Ca656af840dff83E8264EcF986CA; // mainnet
    bytes32 internal keyHash =
    0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef; // mainnet

    uint32 internal callbackGasLimit = 1000000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    uint256[] public allRandomNumbers;
    uint256[] public allRequestIds;
    mapping(uint => uint) public blockToRandomNumber;
    mapping(uint => RandomNumberRequested) public requestIdToRandomNumberMetaData;

    event RandomNumberGenerated(
        uint randomNumber,
        uint256 chainlinkRequestId,
        string title
    );

    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    /*
     * @notice request a random integer within given bounds
     * @param _minValue - minimum value of the random number (inclusive)
     * @param _maxValue - maximum value of the random number (inclusive)
     * @param _title - reason for the random number request
     * @return requestID - id of the request rng for chainlink response
     */
    function requestRandomWords(
        uint _minValue,
        uint _maxValue,
        string memory _title
    ) public onlyOwner returns (uint256 requestID) {
        requestID = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        RandomNumberRequested storage newRng = requestIdToRandomNumberMetaData[requestID];
        newRng.minValue = _minValue;
        newRng.maxValue = _maxValue;
        newRng.title = _title;
        allRequestIds.push(requestID);
    }

    // @notice callback function called by chainlink
    function fulfillRandomWords(uint256 requestID, uint256[] memory randomWords)
    internal
    override
    {
        uint randomResponse = randomWords[0];
        // get the random number
        RandomNumberRequested memory RNGParams = requestIdToRandomNumberMetaData[requestID];
        uint randomNumber = (randomResponse % (RNGParams.maxValue + 1 - RNGParams.minValue)) + RNGParams.minValue;
        RNGParams.randomWords = randomResponse;
        RNGParams.randomNumber = randomNumber;
        requestIdToRandomNumberMetaData[requestID] = RNGParams;

        require(blockToRandomNumber[block.number] == 0, "already fetched random for this block");

        blockToRandomNumber[block.number] = randomNumber;
        emit RandomNumberGenerated(randomNumber, requestID, requestIdToRandomNumberMetaData[requestID].title);
        allRandomNumbers.push(randomResponse);
    }

    // @notice Disable renounceOwnership. Only callable by owner.
    function renounceOwnership() public virtual override onlyOwner {
        revert("Ownership cannot be renounced");
    }
}