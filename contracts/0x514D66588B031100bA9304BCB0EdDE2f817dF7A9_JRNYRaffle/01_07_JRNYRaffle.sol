// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract JRNYRaffle is
    VRFV2WrapperConsumerBase,
    ConfirmedOwner
{
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    struct RequestStatus {
        uint256 paid;
        bool fulfilled;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests;


    struct Raffle {
        uint256 requestId;
        uint32 entries;
    }
    mapping(string => Raffle)
        public s_raffles;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 numWords = 1;

    // sepolia
    // address linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    // address wrapperAddress = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

    // mainnet
    address linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address wrapperAddress = 0x5A861794B927983406fCE1D062e00b9368d97Df6;

    constructor()
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {}

    function startRaffle(
        string calldata _raffleName,
        uint32 _raffleEntries
    )
        external
        onlyOwner
        returns (Raffle memory raffle)
    {
        require(s_raffles[_raffleName].requestId == 0, "raffle already exists, name must be unique");
        uint256 requestId = requestRandomWords();
        raffle = Raffle({
            requestId: requestId,
            entries: _raffleEntries
        });
        s_raffles[_raffleName] = raffle;
        return raffle;
    }

    function checkWinner(
        string calldata _raffleName
    )
        external
        view
        returns (uint256 winner)
    {
        Raffle memory _raffle = s_raffles[_raffleName];
        require(_raffle.requestId > 0, "raffle not found");
        RequestStatus memory _request = s_requests[_raffle.requestId];
        require(_request.paid > 0, "chainlink request not found");
        require(_request.fulfilled == true, "chainlink request is still not confirmed");
        winner = _request.randomWords[0] % _raffle.entries;
        return winner;
    }

    function setCallbackGasLimit(
        uint32 _callbackGasLimit
    )
        external
        onlyOwner
    {
        callbackGasLimit = _callbackGasLimit;
    }

    function setRequestConfirmations(
        uint16 _requestConfirmations
    )
        external
        onlyOwner
    {
        requestConfirmations = _requestConfirmations;
    }


    function requestRandomWords()
        internal
        returns (uint256 requestId)
    {
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}