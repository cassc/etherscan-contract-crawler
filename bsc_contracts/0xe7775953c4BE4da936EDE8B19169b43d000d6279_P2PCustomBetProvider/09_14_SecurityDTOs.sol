// SPDX-License-Identifier: MIT

// solhint-disable-next-line
pragma solidity 0.8.2;

library SecurityDTOs {
    struct ChangeAlterToken {
        address newAlterToken;
        uint createdDate;
        uint votingCode;
    }

    struct AddOwner {
        address newOwner;
        uint createdDate;
        uint votingCode;
    }

    struct RemoveOwner {
        address ownerToRemove;
        uint createdDate;
        uint votingCode;
    }

    struct TransferCompany {
        address newCompanyAddress;
        uint createdDate;
        uint votingCode;
    }

    struct TakeFee {
        uint amount;
        address targetAddress;
        bool isAlternative;
        uint createdDate;
        uint votingCode;
    }

    struct VotingInfo {
        address initiator;
        uint currentNumberOfVotesPositive;
        uint currentNumberOfVotesNegative;
        uint startedDate;
        string votingCode;
    }
}