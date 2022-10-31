// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

library BaseTypes {

    // enums: low level
    enum SimpleVote {
        NO,
        YES
    }
    enum VotingStatus {
        ACCEPTED,
        REJECTED,
        NOT_RESOLVED
    }

    // structs: low level
    struct Raise {
        string raiseId;
        uint256 hardcap;
        uint256 softcap;
        uint256 start;
        uint256 end;
    }
    struct Vested {
        address erc20;
        uint256 amount;
    }
    struct Milestone {
        uint256 number;
        uint256 deadline;
        bytes32 hashedDescription;
    }

}