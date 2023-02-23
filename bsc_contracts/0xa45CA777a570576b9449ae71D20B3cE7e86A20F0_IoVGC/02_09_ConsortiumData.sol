pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT

import "./iERC20.sol";

// This contract contains the data for IoVGC contract and must be inherited by it and its delegated contract.
contract ConsortiumData {
    //****************************************************************************
    //* Data
    //****************************************************************************
    string public version = "0.1.0";
    string public name = "IoVGC: Internet of Vehicles Global Consortium";
    struct Proposal {
        uint8 approved; // 1: Voting state, 2: Approved, 3: Rejected, 4: Expired
        uint24 approversCount;
        uint24 rejectorsCount;
        uint40 offerTime;
        uint8 pType;
            // 1: Add Member, 2: Remove Member, 3: Pay IoVT, 4: Pay Token, 5: Pay BNB, 6: Approve Pay IoVT, 7: Pay Delegated IoVT,
            // 11: Change Consortium (Transfer Members), 12: Only Change Consortium, 13: Block Account, 14: Unblock Account, 
            // 15: Free Voting, 16: Send Data, 17: Change Distributor Target Address, 18: Change DistributorOwner
        string description;
        address payable account;
        address token;
        uint value;
        string name;
        mapping(address => uint8) votes; // 2: Approved, 3: Rejected
        bytes data;
    }
    Proposal[] proposals;
    uint[] openProposals;
    struct Member {
        string name;
        bool isMember;
        uint24 id;
//        uint16 role;
    }
    mapping (address => Member) members;
    uint24 membersCount;
    address[] memberAddresses;
    uint8 quorumCoefficient = 2;
    uint8 quorumDivisor = 3;
    uint40 maxVotingDuration = 30 days;
    address public IoVTAddress;
    iERC20 IoVT;
// Messages in require statements.
    string message1 = "Insufficient balance.";
    string message2 = "Invalid portion id.";
    string message3 = "This proposal is not in voting mode.";
    string message4 = "The address is member of the consortium.";
    string message5 = "Account is blocked before.";
    string message6 = "Invalid Proposal id.";
    string message7 = "The address is not member of the consortium.";
    string message8 = "Invalid token address.";
    string message9 = "Account is not blocked.";
    string message10 = "IoVT address is not set in the new consortium contract.";
    string message11 = "Invalid consortium contract.";
    string message12 = "Invalid member id.";
    string message13 = "You are the only member.";
    string message14 = "Consortium is not the owner of distributor contract.";
    string message15 = "Invalid distributor contract.";

}