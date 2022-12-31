// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./INFTServiceTypes.sol";   
/**
 * Interface of NFTicket
 */

 
interface INFTicket {
    function mintNFTicket(address recipient, Ticket memory ticket)
        external
        payable 
        returns (Ticket memory);
/*
    function lockTicket(
        uint256 ticketID,
        address presenter,
        address serviceProviderContract,
        uint256 reduceCreditsBy
    ) external ;
    function releaseTicket(
        uint256 ticketID, 
        address ticketReceiver, 
        address serviceProviderContract,
        uint256 reduceCreditsBy
    ) external ;
*/
    function updateServiceType(uint256 ticketID, uint32 serviceDescriptor)
        external
        returns(uint256 _sD);
    
    function withDrawCredits(uint256 ticketID, address erc20Contract, uint256 credits, address sendTo)
        external;
        
    function withDrawERC20(uint256 ticketID, address erc20Contract, uint256 amountERC20Tokens, address sendTo)
        external;
    function topUpTicket(uint256 ticketID, uint256 creditsAdded, address erc20Contract, uint256 amountERC20Tokens)
        external returns(uint256 creditsAffordable, uint256 chargedERC20);

    function registerServiceProvider(address serviceProvider, uint32 serviceDescriptor, address serviceProviderWallet) 
        external returns(uint16 status);
    function registerResellerServiceProvider(address serviceProvider, address reseller, address resellerWallet)
        external returns(uint16 status); 

    /*
    function consumeCredits(address serviceProvider, uint256 ticketID, uint256 credits)
        external 
        returns(uint256 creditsConsumed, uint256 creditsRemain);
    */

    function getTransactionPoolSize() external view returns (uint256);

    function getServiceProviderPoolSize(address serviceProvider)
        external
        view
        returns (uint256 poolSize);

    function getTotalTicketPoolSize() 
        external 
        view 
        returns (uint256); 

    function getTicketData(uint256 ticketID)
        external
        view
        returns (Ticket memory);

    function getTicketBalance(uint256 ticketID) 
        external 
        view 
        returns (uint256); 

    function getTreasuryOwner()
        external
        returns(address);
    
    function getTicketProcessor()
        external
        returns(address);
    
    
    event IncomingERC20(
        uint256 indexed ticketID,
        address indexed erc20Contract,
        uint256 amountERC20Tokens,
        address sender,
        address owner,
        uint32  indexed serviceDescriptor
    );

    event IncomingFunding(
        uint256 indexed ticketID,
        address indexed erc20Contract,
        address sender,
        address owner,
        uint256 creditsAdded,
        uint256 tokensAdded,
        uint32  indexed serviceDescriptor
    );

    event WithDrawCredits(
        uint256 indexed ticketID,
        address indexed erc20Contract,
        uint256 amountCredits,
        address indexed from,
        address to 
    );
    event WithDrawERC20(
        uint256 indexed ticketID,
        address indexed erc20Contract,
        uint256 amountERC20Tokens,
        address indexed from,
        address to 
    );

    event TicketSubmitted(
        address indexed _contract,
        uint256 indexed ticketID,
        uint256 indexed serviceType,
        uint256 deductedFee
    );

    event TopUpTicket(
        uint256 indexed ticketID, 
        uint256 creditsAdded, 
        address indexed erc20Contract, 
        uint256 amountERC20Tokens, 
        uint256 creditsAffordable, 
        uint256 chargedERC20);

    event SplitRevenue(
        uint256 indexed newTicketID,
        uint256 value,
        uint256 serviceFee,
        uint256 resellerFee,
        uint256 transactionFee
    );
    event SchemaRegistered(string name, DataSchema schema);
    event ConsumedCredits(
        uint256 indexed _tID,
        uint256 creditsConsumed,
        uint256 creditsRemain
    );
    event RegisterServiceProvider(
        address indexed serviceProvideContract,
        uint32 indexed serviceDescriptor,
        uint16 status
    );
    event WrongSender(
        address sender,
        address expectedSender,
        string message
    );
    event InsufficientPayment(
        uint256 value,
        uint256 credits,
        uint256 pricePerCredit
    );

}