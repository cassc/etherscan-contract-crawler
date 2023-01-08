// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

import "./Interfaces.sol";

contract Declerations {

    address public master;
    uint256 public usageFee;
    uint256 public lotteryCount;

    uint64 public subscriptionId;

    uint256 constant public MAX_VALUE_HOUSE_PERCENTAGE = 50;
    uint256 constant public MAX_FEE_PERCENTAGE = 10;
    uint256 constant public PERCENT_BASE = 100;
    uint256 constant public DEADLINE_REDEEM = 30 days;
    uint256 constant public SECONDS_IN_DAY = 86400;
    uint32 constant public CALLBACK_GAS_LIMIT = 250000;
    uint16 constant public CONFIRMATIONS = 5;

    address constant public ZERO_ADDRESS = address(0x0);

    address constant public LINK_TOKEN_ADDRESS = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    bytes32 constant public KEY_HASH = 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92;

    enum Status {
        PURCHASING,
        REQUEST_ORACLE,
        FINALIZED
    }

    struct BaseData {
        Status status;
        address owner;
        address winner;
        address nftAddress;
        uint256 nftId;
        address sellToken;
        uint256 closingTime;
        uint256 timeLastRequest;
    }

    struct TicketData {
        uint256 totalPrice;
        uint256 ticketPrice;
        uint256 totalTickets;
        uint256 soldTickets;
        uint256 luckyNumber;
    }

    mapping(uint256 => BaseData) public baseData;
    mapping(uint256 => TicketData) public ticketData;

    // this is for oracle to store requestID
    mapping(uint256 => uint256) public requestIdToIndex;

    // to store ticket ownership per address per lottery
    mapping(uint256 => mapping(uint256 => address)) public tickets;
}