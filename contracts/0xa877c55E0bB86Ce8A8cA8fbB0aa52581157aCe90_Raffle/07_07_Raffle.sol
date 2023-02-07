// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

/**
 * @title Raffle
 * @author Apymon
 *
 * Will you win?
 *
 **/

contract Raffle is VRFV2WrapperConsumerBase, ConfirmedOwner {
    struct RaffleStatus {
        uint256 paid;
        bool fulfilled;
        uint32 numWinners;
        uint256 numEntries;
        uint256[] randomWinners;
    }

    event RaffleRequest(
        uint256 requestId,
        uint32 numWinners,
        uint256 numEntries
    );

    event RaffleResult(uint256 requestId, uint256[] winningNumbers);

    mapping(uint256 => RaffleStatus) public statuses;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    uint32 callbackGasLimit = 150000;
    uint16 requestConfirmations = 3;

    address linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address wrapperAddress = 0x5A861794B927983406fCE1D062e00b9368d97Df6;

    constructor()
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {}

    function requestRaffle(uint32 _numWinners, uint256 _numEntries)
        external
        onlyOwner
        returns (uint256 requestId)
    {
        require(_numWinners > 0, "need at least one winner");
        require(_numWinners <= 5, "need 5 or less winners");
        require(_numEntries > _numWinners, "must be more entries and winners");

        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            _numWinners
        );

        statuses[requestId] = RaffleStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWinners: new uint256[](0),
            numWinners: _numWinners,
            numEntries: _numEntries,
            fulfilled: false
        });

        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RaffleRequest(requestId, _numWinners, _numEntries);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(statuses[_requestId].paid > 0, "request not found");
        statuses[_requestId].fulfilled = true;

        uint256 length = _randomWords.length;

        uint256[] memory winningNumbers = new uint256[](length);

        uint256 _numEntries = statuses[_requestId].numEntries;

        for (uint256 i = 0; i < length; i++) {
            winningNumbers[i] = (_randomWords[i] % _numEntries) + 1;
        }

        statuses[_requestId].randomWinners = winningNumbers;

        emit RaffleResult(_requestId, winningNumbers);
    }

    function getRaffleStatus(uint256 _requestId)
        external
        view
        returns (
            uint256 paid,
            bool fulfilled,
            uint32 numWinners,
            uint256 numEntries,
            uint256[] memory randomWinners
        )
    {
        require(statuses[_requestId].paid > 0, "request not found");
        RaffleStatus memory request = statuses[_requestId];
        return (
            request.paid,
            request.fulfilled,
            request.numWinners,
            request.numEntries,
            request.randomWinners
        );
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}