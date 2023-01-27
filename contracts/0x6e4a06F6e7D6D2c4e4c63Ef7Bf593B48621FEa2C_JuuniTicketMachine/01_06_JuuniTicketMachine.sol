// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

//   _  _ _  _ _  _  _  _
//  | || | || | || \| || |
//  n_|||U || U || \\ || |
// \__/|___||___||_|\_||_|

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

struct Entry {
    // participant address
    address participantAddress;
    // start index inclusive
    uint64 startIndex;
    // end index inclusive
    uint64 endIndex;
}

struct EntryRequest {
    // participant address
    address participantAddress;
    // quantity of tickets
    uint256 ticketCount;
}

struct Reward {
    address rewardNFTAddress;
    uint256 tokenId;
}

contract JuuniTicketMachine is VRFConsumerBaseV2, Ownable {
    using Counters for Counters.Counter;

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    Counters.Counter private _raffleId;
    // _raffleId => address[] list of winner addresses for a raffle id
    mapping(uint256 => address[]) public winners;
    // address => _raffleId => totalEntries
    mapping(address => mapping(uint256 => uint256)) public raffleEntriesTracker;
    // _raffleId => Entry[]
    mapping(uint256 => Entry[]) private raffleEntries;
    // _raffleId => uint256[] raffle id to list of random numbres
    mapping(uint256 => uint256[]) public randomWordsByRaffle;
    // _raffleId => Reward, a list of reward for raffle
    mapping(uint256 => Reward[]) public raffleRewards;
    // To read past raffles
    uint256[] private finishedRaffles;

    // requestId --> requestStatus
    mapping(uint256 => RequestStatus) public s_requests;
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash =
        0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805;

    uint32 callbackGasLimit = 600000;

    uint16 requestConfirmations = 5;

    error AlreadyRegistered();
    error InvalidEntries();
    error InvalidRaffle();
    error InvalidWinnersCount();
    error NeedMoreRandomNumbers();
    error NoTicketsFound();
    error RaffleAlreadyResolved();
    error RaffleNoEntries();
    error RaffleNotAvailable();
    error RaffleRewardsNotRegistered();
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event RequestSent(uint256 requestId, uint32 numWords);

    modifier ensureRaffleIsOpen() {
        uint256 currentRaffleId = _raffleId.current();

        if (winners[currentRaffleId].length > 0) revert RaffleAlreadyResolved();

        if (raffleRewards[currentRaffleId].length == 0)
            revert RaffleRewardsNotRegistered();

        _;
    }

    constructor(
        uint64 subscriptionId,
        address coordinatorAddress
    ) VRFConsumerBaseV2(coordinatorAddress) {
        COORDINATOR = VRFCoordinatorV2Interface(coordinatorAddress);

        s_subscriptionId = subscriptionId;
    }

    function drawRandomNumbers(
        uint32 winnersCount
    ) external onlyOwner ensureRaffleIsOpen returns (uint256 requestId) {
        if (winnersCount == 0 || winnersCount >= 10)
            revert InvalidWinnersCount();
        uint32 wordsToRequest = winnersCount * 2;

        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            wordsToRequest
        );

        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });

        emit RequestSent(requestId, wordsToRequest);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        uint256 currentRaffleId = _raffleId.current();

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        unchecked {
            for (uint256 i = 0; i < _randomWords.length; i++) {
                randomWordsByRaffle[currentRaffleId].push(_randomWords[i]);
            }
        }

        emit RequestFulfilled(_requestId, _randomWords);
    }

    function drawWinners() external onlyOwner ensureRaffleIsOpen {
        uint256 currentRaffleId = _raffleId.current();

        if (currentRaffleId == 0) revert RaffleNotAvailable();

        Entry[] storage entries = raffleEntries[currentRaffleId];

        if (entries.length == 0) revert RaffleNoEntries();

        uint256[] memory randomWords = randomWordsByRaffle[currentRaffleId];
        uint256 winnersCount = raffleRewards[currentRaffleId].length;
        uint256 selectedWinners;

        for (uint256 i = 0; i < randomWords.length; i++) {
            // safe to convert as entries[entries.length - 1].endIndex is going to be uint64 and we're modding by it
            uint64 randomIndex = uint64(
                randomWords[i] % _totalEntries(currentRaffleId)
            );

            Entry storage foundEntry = _searchRaffleBS(
                entries,
                0,
                uint64(entries.length - 1),
                randomIndex
            );

            if (_isAddressInCurrentWinnersList(foundEntry.participantAddress)) {
                // duplicate let's go to next random word
                continue;
            }

            winners[currentRaffleId].push(foundEntry.participantAddress);
            selectedWinners++;

            // Done selecting
            if (selectedWinners == winnersCount) {
                break;
            }
        }

        if (selectedWinners != winnersCount) revert NeedMoreRandomNumbers();
        finishedRaffles.push(currentRaffleId);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function getRandomWordsByRaffle(
        uint256 raffleId
    ) external view returns (uint256[] memory randomWords) {
        randomWords = randomWordsByRaffle[raffleId];
    }

    function getWinnersByRaffle(
        uint256 raffleId
    ) external view returns (address[] memory winnerAddresses) {
        winnerAddresses = winners[raffleId];
    }

    function getFinishedRaffles()
        external
        view
        returns (uint256[] memory raffles)
    {
        raffles = finishedRaffles;
    }

    function getNumWinnersByRaffle(uint256 id) external view returns (uint256) {
        return winners[id].length;
    }

    function getRaffleRewards(
        uint256 raffleId
    ) external view returns (Reward[] memory rewards) {
        rewards = raffleRewards[raffleId];
    }

    function totalEntries() external view returns (uint256 numEntries) {
        numEntries = _totalEntries(_raffleId.current());
    }

    function currentRaffle() external view returns (uint256) {
        return _raffleId.current();
    }

    function incrementRaffle() public onlyOwner {
        _raffleId.increment();
    }

    function setEntries(
        EntryRequest[] calldata newEntries
    ) external onlyOwner ensureRaffleIsOpen {
        if (newEntries.length == 0) revert InvalidEntries();

        uint256 raffleId = _raffleId.current();

        Entry[] memory currentRaffleEntries = raffleEntries[raffleId];
        uint64 startIndex = 0;

        // If there is already entries, take last one's end + 1 as new start
        if (raffleEntries[raffleId].length > 0) {
            startIndex =
                currentRaffleEntries[currentRaffleEntries.length - 1].endIndex +
                1;
        }

        unchecked {
            for (uint256 i = 0; i < newEntries.length; i++) {
                address participantAddress = newEntries[i].participantAddress;
                uint64 quantity = uint64(newEntries[i].ticketCount);

                if (newEntries[i].ticketCount == 0) {
                    revert NoTicketsFound();
                }

                if (raffleEntriesTracker[participantAddress][raffleId] > 0) {
                    revert AlreadyRegistered();
                }

                raffleEntries[raffleId].push(
                    Entry({
                        startIndex: startIndex,
                        endIndex: startIndex + quantity - 1,
                        participantAddress: participantAddress
                    })
                );

                // move start index
                startIndex = startIndex + quantity;

                raffleEntriesTracker[participantAddress][raffleId] = quantity;
            }
        }
    }

    function setRewards(Reward[] calldata rewards) external onlyOwner {
        raffleRewards[_raffleId.current()] = rewards;
    }

    function _totalEntries(uint256 raffleId) internal view returns (uint256) {
        Entry[] storage entries = raffleEntries[raffleId];

        if (entries.length == 0) return 0;

        return entries[entries.length - 1].endIndex + 1;
    }

    function _isAddressInCurrentWinnersList(
        address addr
    ) internal view returns (bool) {
        uint256 currentRaffleId = _raffleId.current();

        unchecked {
            for (uint256 i = 0; i < winners[currentRaffleId].length; i++) {
                if (winners[currentRaffleId][i] == addr) {
                    return true;
                }
            }

            return false;
        }
    }

    function _searchRaffleBS(
        Entry[] storage entries,
        uint64 start,
        uint64 end,
        uint64 target
    ) internal returns (Entry storage) {
        if (start == end) {
            return entries[start];
        }

        uint64 mid = (start + end) / 2;

        if (
            entries[mid].startIndex <= target && entries[mid].endIndex >= target
        ) {
            return entries[mid];
        }

        if (target < entries[mid].startIndex) {
            return _searchRaffleBS(entries, start, mid - 1, target);
        }

        return _searchRaffleBS(entries, mid + 1, end, target);
    }
}