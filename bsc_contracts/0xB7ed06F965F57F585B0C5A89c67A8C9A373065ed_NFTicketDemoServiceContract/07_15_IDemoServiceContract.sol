// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../../interfaces/INFTServiceTypes.sol";

interface IDemoServiceContract {
    event TicketMinted(uint256 indexed ticketId, address indexed consumer);
    event CreditRedeemed(uint256 indexed ticketId, address indexed consumer);
    event BalanceAdded(
        uint256 indexed ticketId,
        address indexed consumer,
        uint256 indexed amount
    );
    event Erc20Withdrawn(
        uint256 indexed ticketId,
        address indexed consumer,
        uint256 indexed amount
    );

    function mintNfticket(string calldata URI) external;

    function redeemNfticket(uint256 ticketId) external;

    function addBalanceToTicket(uint256 ticketId) external;

    function getErc20(uint256 ticketId) external;

    function setNumCredits(uint256 newNumOfCredits) external;

    function setNumErc20PerConsumer(uint256 number) external;

    function setTicketServiceDescriptor(uint32 serviceDescriptor) external;

    function setCashVoucherServiceDescriptor(uint32 serviceDescriptor) external;

    function withdrawRemainingErc20() external;
}