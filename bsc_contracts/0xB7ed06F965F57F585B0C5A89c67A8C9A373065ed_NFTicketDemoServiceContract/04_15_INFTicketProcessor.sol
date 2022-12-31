// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./INFTServiceTypes.sol";

interface INFTicketProcessor {

    function lockTicket(
        uint256 ticketID,
        address presenterAddress,
        address serviceProviderContract,
        uint256 reduceCreditsBy
    ) external ;

    function releaseTicket(
        uint256 ticketID, 
        address ticketReceiver, 
        address serviceProviderContract, 
        uint256 reduceCreditsBy
    ) external ;

    function presentTicket(
        uint256 ticketID,
        address presenter,
        address _serviceProvider,
        uint256 credits,
        uint8 checkInMode
    ) external returns (Ticket memory);

    function presentTicket(
        uint256 ticketID,
        address presenter,
        address _serviceProvider,
        uint256 credits,
        address ticketReceiver,
        uint8 checkInMode
    ) external returns (Ticket memory ticket);

    function topUpTicket(uint256 ticketID, uint32 serviceDescriptor, uint256 creditsAdded, address erc20Token, uint256 numberERC20Tokens) 
        external
        returns (uint256 credits); 

    event TicketPresented(
        uint256 indexed ticketID, 
        address indexed from, 
        address indexed to, 
        uint256 creditsPresented
    );

    event CreditsToService(
        uint256 indexed ticketID,
        uint256 credits,
        uint256 value,
        address indexed payer,
        address indexed payee
    );
}