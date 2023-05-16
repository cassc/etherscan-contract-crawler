// SPDX-License-Identifier: MIT

// solhint-disable-next-line
pragma solidity 0.8.2;

import "../../processing/TokenProcessing.sol";
import "./CustomProcessor.sol";

contract P2PCustomBetProvider is TokenProcessing, CustomProcessor {
    mapping(uint => CustomDTOs.CustomBet) private customBets;
    mapping(uint => CustomDTOs.CustomMatchingInfo) private matchingInfo;
    mapping(address => mapping(uint => CustomDTOs.JoinCustomBetClientList)) private clientInfo;
    mapping(address => uint[]) private clientBets;
    mapping(address => uint) public clientBetsLength;
    uint public customBetIdCounter;

    constructor(address mainToken, address[] memory owners) TokenProcessing(mainToken) {
        for (uint i = 0; i < owners.length; i++) {
            addOwner(owners[i]);
        }
    }

    function getClientBets(address client, uint offset, uint size) external view returns (uint[] memory) {
        uint resultSize = size;
        for (uint i = offset; i < offset + size; i++) {
            if (clientBets[client].length <= i) {
                resultSize = i - offset;
                break;
            }
        }
        uint[] memory result = new uint[](resultSize);
        for (uint i = offset; i < offset + resultSize; i++) {
            result[i - offset] = clientBets[client][i];
        }
        return result;
    }

    function getCustomBet(uint betId) external view returns (CustomDTOs.CustomBet memory, uint, uint, uint, uint) {
        CustomDTOs.CustomMatchingInfo storage info = matchingInfo[betId];
        return (customBets[betId], info.leftFree, info.leftLocked, info.rightFree, info.rightLocked);
    }

    function getCustomClientJoins(address client, uint betId) external view returns (CustomDTOs.JoinCustomBetClient[] memory) {
        CustomDTOs.JoinCustomBetClient[] memory clientList = new CustomDTOs.JoinCustomBetClient[](clientInfo[client][betId].length);
        for (uint i = 0; i < clientInfo[client][betId].length; i++) {
            clientList[i] = extractCustomJoinBetClientByRef(matchingInfo[betId], clientInfo[client][betId].joinListRefs[i]);
        }
        return clientList;
    }

    function closeCustomBet(uint betId, string calldata finalValue, bool targetSideWon) external onlyCompany {
        require(keccak256(abi.encodePacked(finalValue)) != keccak256(abi.encodePacked("")), "P2PCustomBetProvider: close error - custom bet can't be closed with empty value");
        CustomDTOs.CustomBet storage customBet = customBets[betId];
        require(customBet.expirationTime < block.timestamp, "P2PCustomBetProvider: close error - expiration error");
        require(customBet.expirationTime + getTimestampExpirationDelay() > block.timestamp, "P2PCustomBetProvider: close error - expiration error with delay");
        require(keccak256(abi.encodePacked(customBet.finalValue)) == keccak256(abi.encodePacked("")), "P2PCustomBetProvider: close error - bet already closed");

        customBet.finalValue = finalValue;
        customBet.targetSideWon = targetSideWon;

        emit CustomBetClosed(
            betId,
            finalValue,
            targetSideWon
        );
    }

    function refundCustomBet(uint betId, address client) external {
        CustomDTOs.CustomBet storage customBet = customBets[betId];
        require(keccak256(abi.encodePacked(customBet.finalValue)) == keccak256(abi.encodePacked("")), "P2PCustomBetProvider: refund - custom haven't to be open");
        require(customBet.expirationTime + getTimestampExpirationDelay() < block.timestamp, "P2PCustomBetProvider: refund - expiration error");

        uint mainTokenToRefund = processRefundingCustomBet(matchingInfo[betId], clientInfo[client][betId]);
        require(mainTokenToRefund > 0, "P2PCustomBetProvider: refund - nothing");
        withdrawalMainToken(client, mainTokenToRefund);

        emit CustomBetRefunded(
            betId,
            client,
            mainTokenToRefund
        );
    }

    function takeCustomPrize(uint betId, address client, bool useAlterFee) external {
        CustomDTOs.CustomBet storage customBet = customBets[betId];
        require(keccak256(abi.encodePacked(customBet.finalValue)) != keccak256(abi.encodePacked("")), "P2PCustomBetProvider: take prize - custom bet wasn't closed");

        uint wonAmount = takePrize(customBet, matchingInfo[betId], clientInfo[client][betId]);

        require(wonAmount > 0, "P2PCustomBetProvider: take prize - nothing");

        uint wonAmountAfterFee = takeFeeFromAmount(msg.sender, wonAmount, useAlterFee);

        withdrawalMainToken(client, wonAmountAfterFee);

        emit CustomPrizeTaken(
            betId,
            client,
            wonAmountAfterFee,
            useAlterFee
        );
    }

    function getCustomWonAmount(uint betId, address client) public view returns (uint) {
        CustomDTOs.CustomBet storage customBet = customBets[betId];
        if (keccak256(abi.encodePacked(customBet.targetValue)) == keccak256(abi.encodePacked(""))) {
            return 0;
        }
        return evaluatePrize(customBet, matchingInfo[betId], clientInfo[client][betId]);
    }

    function createCustomBet(CustomDTOs.CreateCustomRequest calldata createRequest, CustomDTOs.JoinCustomRequest calldata joinRequest) external returns (uint) {
        // lock - 60 * 3
        // expiration - 60 * 3
        require(createRequest.lockTime >= block.timestamp + 60 * 3, "P2PCustomBetProvider: create - lock time test");
        require(createRequest.expirationTime >= createRequest.lockTime + 60 * 3, "P2PCustomBetProvider: create - expirationTime time");

        uint betId = customBetIdCounter++;
        customBets[betId] = CustomDTOs.CustomBet(
            betId,
            createRequest.eventId,
            createRequest.hidden,
            createRequest.lockTime,
            createRequest.expirationTime,
            createRequest.targetValue,
            createRequest.targetSide,
            createRequest.coefficient,
            "",
            false
        );

        emit CustomBetCreated(
            betId,
            createRequest.eventId,
            createRequest.hidden,
            createRequest.lockTime,
            createRequest.expirationTime,
            createRequest.targetValue,
            createRequest.targetSide,
            createRequest.coefficient,
            msg.sender
        );

        joinCustomBet(betId, joinRequest);

        return betId;
    }

    function cancelCustomJoin(uint betId, uint joinIdRef) external {
        CustomDTOs.JoinCustomBetClient storage clientJoin = extractCustomJoinBetClientByRef(matchingInfo[betId], clientInfo[msg.sender][betId].joinListRefs[joinIdRef]);

        require(clientJoin.freeAmount != 0, "P2PCustomBetProvider: cancel - free amount empty");
        require(clientJoin.client == msg.sender, "P2PCustomBetProvider: cancel - not owner");

        uint mainTokenToRefund = cancelCustomBet(matchingInfo[betId], clientJoin);
        withdrawalMainToken(clientJoin.client, mainTokenToRefund);

        emit CustomBetCancelled(
            betId,
            clientJoin.client,
            joinIdRef,
            mainTokenToRefund
        );
    }


    function joinCustomBet(uint betId, CustomDTOs.JoinCustomRequest calldata joinRequest) public {
        require(customBets[betId].lockTime >= block.timestamp, "P2PCustomBetProvider: cancel - lock time");
        clientBets[msg.sender].push(betId);
        clientBetsLength[msg.sender]++;

        CustomDTOs.CustomBet storage bet = customBets[betId];
        CustomDTOs.JoinCustomBetClientList storage clientBetList = clientInfo[msg.sender][betId];

        // deposit amounts
        DepositedValue memory depositedValue = deposit(msg.sender, joinRequest.amount);

        // Only mainAmount takes part in the custom bet
        CustomDTOs.JoinCustomBetClient memory joinBetClient = CustomDTOs.JoinCustomBetClient(
            0,
            msg.sender,
            depositedValue.mainAmount,
            0,
            joinRequest.side,
            clientBetList.length
        );

        // Custom bet enrichment with matching
        (CustomDTOs.JoinCustomBetClient storage storedJoinBetClient, uint sidePointer) = joinCustomBet(bet, matchingInfo[betId], joinBetClient);

        // Add to client info
        clientBetList.joinListRefs[clientBetList.length++] = CustomDTOs.JoinCustomBetClientRef(joinBetClient.targetSide, sidePointer);

        emit CustomBetJoined(
            joinRequest.side,
            joinRequest.amount,
            msg.sender,
            betId,
            storedJoinBetClient.id,
            clientBetList.length - 1
        );
    }

    event CustomBetCreated(
        uint id,
        string eventId,
        bool hidden,
        uint lockTime,
        uint expirationTime,
        string targetValue,
        bool targetSide,
        uint coefficient,
        address indexed creator
    );

    event CustomBetJoined(
        bool side,
        uint mainAmount,
        address indexed client,
        uint betId,
        uint joinId,
        uint joinIdRef
    );

    event CustomBetCancelled(
        uint betId,
        address indexed client,
        uint joinIdRef,
        uint mainTokenRefunded
    );

    event CustomBetClosed(
        uint betId,
        string finalValue,
        bool targetSideWon
    );

    event CustomBetRefunded(
        uint betId,
        address indexed client,
        uint mainTokenRefunded
    );

    event CustomPrizeTaken(
        uint betId,
        address indexed client,
        uint amount,
        bool useAlterFee
    );
}