// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract ChimpersRaffle is VRFConsumerBaseV2, ConfirmedOwner {
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
    mapping(uint256 => RaffleStatus) public _raffles; /* requestId --> RaffleStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 _subscriptionId;
    address _vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 _keyHash = 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92;
    uint32 _callbackGasLimit = 100000;
    uint16 _requestConfirmations = 3;
    uint32 _numWords = 1;

    uint256 public lastRequestId;
    uint256[] public requestIds;
    
    constructor(uint64 subscriptionId)
        VRFConsumerBaseV2(_vrfCoordinator)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            _vrfCoordinator
        );
        _subscriptionId = subscriptionId;
    }

    function startRaffle(
        string memory ipfsHash,
        uint256 numEntries,
        uint256 numWinners
    ) external
        onlyOwner
    {
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

    function selectWinners(uint256 requestId)
        external
        onlyOwner
    {
        require(_raffles[requestId].exists, "request not found");
        require(_raffles[requestId].fulfilled, "request not fulfilled");

        uint256[] memory winners = new uint256[](_raffles[requestId].numWinners);
      
        for (uint256 i = 0; i < _raffles[requestId].numWinners; i++) {      
            winners[i] = (uint256(keccak256(abi.encode(_raffles[requestId].randomWords, i))) % _raffles[requestId].numEntries) + 1;
        }

        _raffles[requestId].winners = winners;
        _raffles[requestId].winnersSelected = true;
    }

    function getRaffle(
        uint256 requestId
    ) external view returns (
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