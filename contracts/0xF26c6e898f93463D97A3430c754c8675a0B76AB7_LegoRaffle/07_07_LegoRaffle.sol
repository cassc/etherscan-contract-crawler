// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @custom:security-contact [email protected]
contract LegoRaffle is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    event RaffleStart(uint256 raffleId);
    event RaffleEnd(uint256 raffleId);
    event TicketPurchase(address buyer, uint256 ticketsLeft);

    IERC20 public TOKEN;

    bool public raffleLive; // = false
    uint256 public raffleId; // = 0

    uint256 public ticketPrice; // in LEGO tokens
    uint256 public ticketsForSale; // = 10
    uint256 public ticketsSold; // = 0

    address[] public ticketHolders;
    mapping(uint256 => mapping(address => uint256)) public tickets;

    function initialize(address tokenAddress_) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        TOKEN = IERC20(tokenAddress_); // IERC20(0x7871F7adA1b9AA5547d2B4D7EB762D5730062336) on mainnet
    }

    // OWNER

    function startRaffle(uint256 ticketsForSale_, uint256 ticketPrice_)
        external
        onlyOwner
    {
        raffleLive = true;
        raffleId++;

        delete ticketHolders;
        ticketsSold = 0;
        ticketsForSale = ticketsForSale_;

        ticketPrice = ticketPrice_;

        emit RaffleStart(raffleId);
    }

    function endRaffle() external onlyOwner {
        raffleLive = false;
        emit RaffleEnd(raffleId);
    }

    function withdraw() external onlyOwner {
        uint256 balance = TOKEN.balanceOf(address(this));
        bool success = TOKEN.transfer(msg.sender, balance);
        require(success, "Token transfer failed");
    }

    function setRafflePrice(uint256 ticketPrice_) external onlyOwner {
        ticketPrice = ticketPrice_;
    }

    // USER

    function enterRaffle(uint256 amount) external nonReentrant {
        require(raffleLive, "Raffle is not live");
        require(
            ticketsSold + amount <= ticketsForSale,
            "Not enough tickets left"
        );

        uint256 totalPrice = ticketPrice * amount;

        bool success = TOKEN.transferFrom(
            msg.sender,
            address(this),
            totalPrice
        );
        require(success, "Token transfer failed");

        ticketsSold += amount;
        if (tickets[raffleId][msg.sender] == 0) {
            ticketHolders.push(msg.sender);
        }
        tickets[raffleId][msg.sender] += amount;

        emit TicketPurchase(msg.sender, ticketsForSale - ticketsSold);
    }
}