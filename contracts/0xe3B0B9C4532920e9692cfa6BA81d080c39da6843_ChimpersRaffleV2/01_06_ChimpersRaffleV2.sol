// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract ChimpersRaffleV2 is VRFConsumerBaseV2, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RaffleStatus {
        uint256[] randomWords;
        bool exists;
        bool fulfilled;
        bool winnersSelected;
        string ipfsHash;
        uint256 numEntries;
        uint256 numWinners;
        uint256[] winners;
    }
    mapping(uint256 => RaffleStatus)
        public _raffles; /* requestId --> RaffleStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 _subscriptionId;
    address _vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 _keyHash =
        0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92;
    uint32 _callbackGasLimit = 100000;
    uint16 _requestConfirmations = 3;
    uint32 _numWords = 1;

    uint256 public lastRequestId;
    uint256[] public requestIds;

    constructor(
        uint64 subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) ConfirmedOwner(msg.sender) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        _subscriptionId = subscriptionId;
    }

    function previousVersion() external pure returns (string memory) {
        return "0x7620de0355f8f451301c814e5702866440488b37";
    }

    function startRaffle(
        string memory ipfsHash,
        uint256 numEntries,
        uint256 numWinners
    ) external onlyOwner {
        require(numWinners < numEntries, "more winners than entries");

        lastRequestId = COORDINATOR.requestRandomWords(
            _keyHash,
            _subscriptionId,
            _requestConfirmations,
            _callbackGasLimit,
            _numWords
        );
        requestIds.push(lastRequestId);
        _raffles[lastRequestId] = RaffleStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false,
            winnersSelected: false,
            ipfsHash: ipfsHash,
            numEntries: numEntries,
            numWinners: numWinners,
            winners: new uint256[](0)
        });
        emit RequestSent(lastRequestId, _numWords);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(_raffles[requestId].exists, "request not found");

        _raffles[requestId].fulfilled = true;
        _raffles[requestId].randomWords = randomWords;

        emit RequestFulfilled(requestId, randomWords);
    }

    function selectWinners(uint256 requestId) external onlyOwner {
        uint256 numWinners = _raffles[requestId].numWinners;
        uint256 numEntries = _raffles[requestId].numEntries;

        uint256[] memory winners = new uint256[](numWinners);

        uint256 i = 0;
        while (i < numWinners) {
            uint256 dedupe = 0;
            uint256 winner = (uint256(
                keccak256(abi.encode(_raffles[requestId].randomWords, i))
            ) % numEntries) +
                1 +
                dedupe;
            if (!existsInArray(winners, winner)) {
                winners[i] = winner;
                ++i;
            } else {
                ++dedupe;
            }
        }

        _raffles[requestId].winners = winners;
        _raffles[requestId].winnersSelected = true;
    }

    function existsInArray(
        uint256[] memory array,
        uint256 target
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == target) {
                return true;
            }
        }
        return false;
    }

    function getRaffle(
        uint256 requestId
    )
        external
        view
        returns (
            uint256[] memory randomWords,
            bool fulfilled,
            bool winnersSelected,
            string memory ipfsHash,
            uint256 numEntries,
            uint256 numWinners,
            uint256[] memory winners
        )
    {
        require(_raffles[requestId].exists, "request not found");
        return (
            _raffles[requestId].randomWords,
            _raffles[requestId].fulfilled,
            _raffles[requestId].winnersSelected,
            _raffles[requestId].ipfsHash,
            _raffles[requestId].numEntries,
            _raffles[requestId].numWinners,
            _raffles[requestId].winners
        );
    }
}