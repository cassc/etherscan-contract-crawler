// SPDX-License-Identifier: MIT

// solhint-disable-next-line
pragma solidity 0.8.2;


library CustomDTOs {
    struct CustomBet {
        uint id;
        string eventId;
        bool hidden;
        uint lockTime;
        uint expirationTime;
        string targetValue;
        bool targetSide;
        uint coefficient;

        string finalValue;
        bool targetSideWon;
    }

    struct CustomMatchingInfo {
        // targetSide == true
        mapping(uint => JoinCustomBetClient) leftSide;
        uint leftLength;
        uint leftLastId;
        // targetSide == false
        mapping(uint => JoinCustomBetClient) rightSide;
        uint rightLength;
        uint rightLastId;
        uint leftFree;
        uint rightFree;
        uint leftLocked;
        uint rightLocked;
    }

    struct JoinCustomBetClientList {
        mapping(uint => JoinCustomBetClientRef) joinListRefs;
        uint length;
    }

    struct JoinCustomBetClientRef {
        bool side;
        uint id;
    }

    struct JoinCustomBetClient {
        uint id;
        address client;
        uint freeAmount;
        uint lockedAmount;
        bool targetSide;
        uint joinRefId;
    }

    struct CreateCustomRequest {
        string eventId;
        bool hidden;
        uint lockTime;
        uint expirationTime;
        string targetValue;
        bool targetSide;
        uint coefficient;
    }

    struct JoinCustomRequest {
        bool side;
        uint amount;
    }
}