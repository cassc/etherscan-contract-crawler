// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IHotpot {
    struct Prize {
        uint128 amount;
        uint128 deadline;
    }

    struct InitializeParams {
        uint256 potLimit;
        uint256 raffleTicketCost;
        uint128 claimWindow;
        uint16 numberOfWinners;
        uint16 fee;
        uint16 tradeFee;
        address marketplace;
        address operator;
    }

    struct RequestStatus {
        bool fullfilled;
        bool exists;
        uint256 randomWord;
    }

    struct BatchTradeParams {
        uint256 _amountInWei; 
        uint16 _sellerIndex;
        uint256 _buyerPendingAmount; 
        uint256 _sellerPendingAmount;
    }

	event GenerateRaffleTickets(
		address indexed _buyer,
		address indexed _seller, 
		uint32 _buyerTicketIdStart,
		uint32 _buyerTicketIdEnd,
		uint32 _sellerTicketIdStart,
		uint32 _sellerTicketIdEnd,
		uint256 _buyerPendingAmount,
		uint256 _sellerPendingAmount
	);
    event WinnersAssigned(address[] _winners);
    event RandomWordRequested(
        uint256 requestId, 
        uint32 fromTicketId, 
        uint32 toTicketId 
    );
    event RandomnessFulfilled(
        uint16 indexed potId, 
        uint256 randomWord
    );
    event Claim(address indexed user, uint256 amount);
    event MarketplaceUpdated(address _newMarketplace);
    event OperatorUpdated(address _newOperator);
    event AirdropAddressUpdated(address _newAidrop);
    event PrizeAmountsUpdated(uint128[] _newPrizeAmounts);
    event NumberOfWinnersUpdated(uint16 _nOfWinners);
    event GenerateAirdropTickets(
        address indexed user, 
        uint32 ticketIdStart,
        uint32 ticketIdEnd
    );

    function initialize(address _owner, InitializeParams calldata params) external;

    function executeTrade(
        uint256 _amount, 
        address _buyer, 
        address _seller, 
        uint256 _buyerPendingAmount, 
        uint256 _sellerPendingAmount
    ) external payable;

    function batchExecuteTrade(
        address buyer,
        BatchTradeParams[] memory trades,
        address[] memory sellers
    ) external payable;

    function executeRaffle(address[] calldata _winners) external;

    function claim() external;
    function claimAirdropTickets(address user, uint32 tickets) external;
    function setTradeFee(uint16 _newTradeFee) external;
    function setOperator(address _newOperator) external;
    function updatePrizeAmounts(uint128[] memory _newPrizeAmounts) external;
    function marketplace() external returns(address);
}