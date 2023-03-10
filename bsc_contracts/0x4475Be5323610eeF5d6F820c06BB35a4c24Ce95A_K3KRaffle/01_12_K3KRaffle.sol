// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract K3KRaffle is VRFConsumerBaseV2, ConfirmedOwner{
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event EventRaffle(address user, uint256 raffleId);

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;

    uint256[] public requestIds;
    uint256 public lastRequestId;
    bytes32 keyHash;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2;


    Counters.Counter private raffleIds;
    struct Raffle {
        uint256 index;
        address user;
        uint256 timeStamp;
        string email;
        bool ad;
        bool og;
        bool wl;
    }

    // [address] = struct Raffle
    mapping (address => Raffle) private raffleList;
    // all raffle address
    EnumerableSet.AddressSet private raffleAllAddress;


    constructor(
        uint64 subscriptionId,
        bytes32 _keyHash,
        address _coordinator
    )
        VRFConsumerBaseV2(_coordinator)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(_coordinator);
        s_subscriptionId = subscriptionId;

        keyHash = _keyHash;
    }

    
    function raffle(string memory _email) public {
        require(raffleAllAddress.contains(msg.sender) == false, "can't duplicate");


        raffleAllAddress.add(msg.sender);


        Raffle storage raffleAdd = raffleList[msg.sender];
        raffleAdd.index = raffleIds.current();
        raffleAdd.timeStamp = block.timestamp;
        raffleAdd.user = msg.sender;
        raffleAdd.email = _email;
        raffleAdd.ad = false;
        raffleAdd.og = false;
        raffleAdd.wl = false;
        

        emit EventRaffle(msg.sender, raffleIds.current());

        raffleIds.increment();
    }


    // ***** public view *****
    function getRaffle(address user) public view returns (Raffle memory raffleData) {
        return raffleList[user];
    }
    function getRaffleAllAddress() public view returns (address[] memory) {
        return raffleAllAddress.values();
    }
    function getRaffleAddress(uint256 index) public view returns (address) {
        return raffleAllAddress.at(index);
    }
    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }


    // ***** onlyOwner *****
    function requestRandomWords() external onlyOwner returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
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
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }
    function resultAD(uint256[] memory indexs) external onlyOwner {
        for (uint i = 0; i < indexs.length; i++) {
            uint256 index =  indexs[i];

            address user = raffleAllAddress.at(index);
            raffleList[user].ad = true;
        }
    }
    function resultOG(uint256[] memory indexs) external onlyOwner {
        for (uint i = 0; i < indexs.length; i++) {
            uint256 index =  indexs[i];

            address user = raffleAllAddress.at(index);
            raffleList[user].og = true;
        }
    }
    function resultWL(uint256[] memory indexs) external onlyOwner {
        for (uint i = 0; i < indexs.length; i++) {
            uint256 index =  indexs[i];

            address user = raffleAllAddress.at(index);
            raffleList[user].wl = true;
        }
    }


    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }
}