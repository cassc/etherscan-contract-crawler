// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

/// @title Contract for requesting random numbers from Chainlink VRF
/// @author Charles Vien
/// @custom:juice 100%
/// @custom:security-contact [email protected]
contract Random is VRFConsumerBaseV2, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool exists;
        bool fulfilled;
        uint256[] randomWords;
    }

    uint64 public immutable subscriptionId;
    VRFCoordinatorV2Interface public immutable coordinator;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 public keyHash;
    uint32 public callbackGasLimit;
    uint32 public numWords;
    uint16 public requestConfirmations;

    mapping(uint256 => RequestStatus) public requests;

    /**
     * @notice Constructor inherits VRFConsumerBaseV2 and ConfirmedOwner
     *
     * @param subscriptionId_ - The ID of the VRF subscription. Must be funded
     * with the minimum subscription balance required for the selected keyHash.
     * @param coordinatorAddress_ - Chainlink VRF Coordinator address
     * @param keyHash_ - Corresponds to a particular oracle job which uses
     * that key for generating the VRF proof. Different keyHash's have different gas price
     * ceilings, so you can select a specific one to bound your maximum per request cost.
     * @param callbackGasLimit_ - How much gas you'd like to receive in your
     * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
     * may be slightly less than this amount because of gas used calling the function
     * (argument decoding etc.), so you may need to request slightly more than you expect
     * to have inside fulfillRandomWords. The acceptable range is [0, maxGasLimit]
     * @param numWords_ - The number of random words you'd like to receive in
     * the fulfillRandomWords callback.
     * @param requestConfirmations_ - How many confirmations the Chainlink node should
     * wait before responding.
     */
    constructor(
        uint64 subscriptionId_,
        address coordinatorAddress_,
        bytes32 keyHash_,
        uint32 callbackGasLimit_,
        uint32 numWords_,
        uint16 requestConfirmations_
    )
        VRFConsumerBaseV2(coordinatorAddress_)
        ConfirmedOwner(msg.sender)
    {
        subscriptionId = subscriptionId_;
        coordinator = VRFCoordinatorV2Interface(coordinatorAddress_);
        keyHash = keyHash_;
        callbackGasLimit = callbackGasLimit_;
        numWords = numWords_;
        requestConfirmations = requestConfirmations_;
    }

    /**
     * @notice This function is called by the VRF Coordinator to fulfill requests
     *
     * @param requestId_ - A unique identifier of the request
     * @param randomWords_ - The VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(
        uint256 requestId_,
        uint256[] memory randomWords_
    )
        internal
        override
    {
        require(requests[requestId_].exists, "Random: request not found");

        requests[requestId_].fulfilled = true;
        requests[requestId_].randomWords = randomWords_;

        emit RequestFulfilled(requestId_, randomWords_);
    }

    /**
     * @notice Requests random words from the VRF Coordinator
     */
    function requestRandomWords()
        external
        onlyOwner
    {
        uint256 requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        requests[requestId] = RequestStatus({
            exists: true,
            fulfilled: false,
            randomWords: new uint256[](0)
        });

        requestIds.push(requestId);

        lastRequestId = requestId;

        emit RequestSent(requestId, numWords);
    }

    /**
     * @notice Returns the status of a request
     *
     * @param requestId_ - A unique identifier of the request
     */
    function getRequestStatus(
        uint256 requestId_
    )
        external
        view
        returns (bool fulfilled, uint256[] memory randomWords)
    {
        require(requests[requestId_].exists, "Random: request not found");

        RequestStatus memory request = requests[requestId_];

        return (request.fulfilled, request.randomWords);
    }

    /**
     * @notice Set the key hash
     *
     * @param keyHash_ - Corresponds to a particular oracle job which uses
     * that key for generating the VRF proof. Different keyHash's have different gas price
     * ceilings, so you can select a specific one to bound your maximum per request cost.
     */
    function setKeyHash(bytes32 keyHash_)
        external
        onlyOwner
    {
        keyHash = keyHash_;
    }

    /**
     * @notice Set the callback gas limit
     *
     * @param callbackGasLimit_ - How much gas you'd like to receive in your
     * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
     * may be slightly less than this amount because of gas used calling the function
     * (argument decoding etc.), so you may need to request slightly more than you expect
     * to have inside fulfillRandomWords. The acceptable range is [0, maxGasLimit]
     */
    function setCallbackGasLimit(uint32 callbackGasLimit_)
        external
        onlyOwner
    {
        callbackGasLimit = callbackGasLimit_;
    }

    /**
     * @notice Set the number of words to receive in the callback
     *
     * @param numWords_ - The number of random words you'd like to receive in 
     * the fulfillRandomWords callback.
     */
    function setNumWords(uint32 numWords_)
        external
        onlyOwner
    {
        numWords = numWords_;
    }

    /**
     * @notice Set the number of confirmations the Chainlink node should wait before responding
     *
     * @param requestConfirmations_ - How many confirmations the Chainlink node should wait before responding.
     * The longer the node waits, the more secure the random value is. It must be greater than the 
     * minimumRequestBlockConfirmations limit on the coordinator contract.
     */
    function setRequestConfirmations(uint16 requestConfirmations_)
        external
        onlyOwner
    {
        requestConfirmations = requestConfirmations_;
    }
}