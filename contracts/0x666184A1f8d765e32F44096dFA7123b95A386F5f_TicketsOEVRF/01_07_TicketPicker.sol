// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract TicketsOEVRF is 
    VRFV2WrapperConsumerBase,
    ConfirmedOwner
{

    event PickCommitted(bytes32 addressesHash, uint256 addressesLength, uint256 requestId);
    event PickFulfilled(bytes32 addressesHash, uint256 addressesLength, uint256 result, uint256 requestId);

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
    mapping(uint256 => RequestStatus) public s_requests; 

    struct PickStatus {
        bytes32 addressesHash;
        uint256 addressesLength;
        bool fulfilled;
        uint256 result;
    }
    mapping(uint256 => PickStatus) public s_picks;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    uint32 callbackGasLimit = 200000;

    uint16 requestConfirmations = 6;

    uint32 numWords = 1;

    // Address LINK - hardcoded for Mainnet
    address linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    // address WRAPPER - hardcoded for Mainnet
    address wrapperAddress = 0x5A861794B927983406fCE1D062e00b9368d97Df6;

    constructor()
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {}

    function commitTicketRequest(bytes32 addressesHash, uint256 addressesLength)
        external
        onlyOwner
        returns (uint256 requestId)
    {
        require(addressesLength > 0, "Must have at least one address");
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
        s_picks[requestId] = PickStatus({
            addressesHash: addressesHash,
            addressesLength: addressesLength,
            fulfilled: false,
            result: 0
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        emit PickCommitted(addressesHash, addressesLength, requestId);
        return requestId;

    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        require(s_picks[_requestId].addressesLength > 0, "pick not found");

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        uint256 addressIndex = _randomWords[0] % s_picks[_requestId].addressesLength;
        s_picks[_requestId].fulfilled = true;
        s_picks[_requestId].result = addressIndex;

        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
        emit PickFulfilled(
            s_picks[_requestId].addressesHash,
            s_picks[_requestId].addressesLength,
            addressIndex,
            _requestId
        );
    }

    function getPickStatus(
        uint256 _requestId
    )
        external
        view
        returns (bytes32 addressesHash, uint256 addressesLength, bool fulfilled, uint256 result) 
    {
        require(s_picks[_requestId].addressesLength > 0, "pick not found");
        PickStatus memory pick = s_picks[_requestId];
        return (pick.addressesHash, pick.addressesLength, pick.fulfilled, pick.result);
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