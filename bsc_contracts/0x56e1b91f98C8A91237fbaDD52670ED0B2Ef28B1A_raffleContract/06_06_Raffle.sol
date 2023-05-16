pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

interface rattle {
    function getEntryCount() external view returns (uint256);
    function campaignId() external view returns (string memory);
}

contract raffleContract is VRFConsumerBaseV2, ConfirmedOwner {
    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;

    VRFCoordinatorV2Interface public COORDINATOR;
    uint64 immutable s_subscriptionId;
    address constant vrfCoordinator = 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE;
    bytes32 constant s_keyHash = 0x114f3da0a805b6a67d6e9cd2ec746f7028f1b7376365af575cfea3550dd1aa04;
    uint32 constant callbackGasLimit = 200000;
    uint16 constant requestConfirmations = 3;
    uint32 constant numWords = 1;
    uint256 public requestId;

    uint256 public totalEntry;
    mapping(uint256 => address) public campaignList;
    uint256 public campaignCount;
    bool public isInitialized;

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) ConfirmedOwner(msg.sender) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function initCampaign(address[] memory _list) external onlyOwner {
        require(!isInitialized, "Already initialized");
        for (uint256 i; i < _list.length;) {
            campaignList[i] = _list[i];
            totalEntry += rattle(_list[i]).getEntryCount();
            unchecked {
                i++;
            }
        }
        campaignCount = _list.length;
        isInitialized = true;
    }

    function reveal() external onlyOwner returns (uint256) {
        require(requestId == 0, "Already reveal");
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
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

        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function getWinnerNumber(uint256 _requestId) public view returns(uint256) {
        return s_requests[_requestId].randomWords[0] % totalEntry;
    }

    function getWinner() public view returns(string memory, address) {
        uint256 idx;
        address winner;
        for (uint256 i; i < campaignCount;) {
            idx += rattle(campaignList[i]).getEntryCount();
            if(idx > getWinnerNumber(requestId)) {
                winner = campaignList[i];
                break;
            }
            unchecked {
                i++;
            }
        }
        return (rattle(winner).campaignId(), winner);
    }

    function getMyCampaignTicket(address _campaignAddress) public view returns(uint256, uint256) {
        uint256 startId;
        uint256 endId;
        uint256 idx;
        for (uint256 i; i < campaignCount;) {
            if(campaignList[i] == _campaignAddress) {
                startId = idx;
                endId = idx + rattle(campaignList[i]).getEntryCount();
                break;
            }
            idx += rattle(campaignList[i]).getEntryCount();
            unchecked {
                i++;
            }
        }
        return (startId, endId - 1);
    }
}