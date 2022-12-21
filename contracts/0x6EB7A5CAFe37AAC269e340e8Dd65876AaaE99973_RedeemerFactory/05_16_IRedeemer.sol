// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRedeemer {
    event RedeemRequested(address indexed user, uint256 amount, bytes32 refId);
    event RedeemApproved(bytes32 refId);
    event RedeemRejected(bytes32 refId);
    event RejectedAmountsTransfered(bytes32 refId, address indexed recipient);

    enum TicketStatus {
        NOT_EXIST,
        PENDING,
        APPROVED,
        TRANSFERED,
        REJECTED
    }

    struct BurnTicket {
        bytes32 refId;
        address from;
        uint256 amount;
        uint256 placedBlock;
        uint256 confirmedBlock;
        bool usedTicket;
        TicketStatus ticketStatus;
    }

    function requestRedeem(
        uint256 amount,
        bytes32 refId
    ) external returns (bool isRequestPlaced);

    function approveTickets(bytes32 refId, bool isApproved) external;

    function transferRejectedAmounts(bytes32 refId, address recipient) external;

    function revertTicketRejection(bytes32 refId) external;

    function getBurnReceiptById(
        bytes32 refId
    ) external view returns (BurnTicket memory);

    function getBurnStatusById(
        bytes32 refId
    ) external view returns (bool, TicketStatus, uint256);

    function setErc20AllowList(address erc20Addr, bool status) external;

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external;

    function increaseAllowanceToBurner(uint amount) external;
}