// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LotteryV2BEP20 is Ownable {
    using SafeMath for uint256;

    IERC20 public token;

    mapping(uint256 => address) private ticket2player;  // ticket => player
    mapping(address => uint256) private player2tickets; // player => tickets
    address[] private players;                          // Number of players
    uint256 private soldTickets = 0;                    // Number of tickets sold in current lottery
    uint256 private gamesTotal = 0;                     // Total number of games played
    uint256 private TICKET_PRICE = 5 ether;             // Ticket price is 5 BEP20 tokens by default
    uint256 private HOST_FEE = 20;                      // Host fee is 20% from jackpot by default
    uint256 private MAX_TICKETS = 5;                    // Max tickets per player is 5 by default
    address private feeAddress;                         // Address to receive fees
    address private lastWinner;                         // Winner address

    constructor(IERC20 _token, address _feeAddress) {
        token = _token;
        feeAddress = _feeAddress;
    }


    // EVENTS
    // -----------------

    event TicketPriceUpdated(uint256 newPrice);
    event HostFeeUpdated(uint256 newHostFee);
    event TicketsBought(address player, uint256 tickets);
    event WinnerPicked(address winner, uint256 prize);


    // GETTERS
    // -----------------

    // Return the price of a ticket
    function getTicketPrice() public view returns (uint256) {
        return TICKET_PRICE;
    }

    function getMaxTickets() public view returns (uint256) {
        return MAX_TICKETS;
    }

    // Get player's bought tickets
    function getPlayerTickets(address player) public view returns (uint256) {
        return player2tickets[player];
    }

    // Return the host fee percent
    function getHostFee() public view returns (uint256) {
        return HOST_FEE;
    }

    // Return number of players
    function getPlayersCount() public view returns (uint256) {
        return players.length;
    }

    // Return last winner
    function getLastWinner() public view returns (address) {
        return lastWinner;
    }


    // SETTERS
    // -----------------

    // Set the ticket price
    function setTicketPrice(uint256 _price) public onlyOwner {
        require(_price > 0, "Price must be greater than 0");
        TICKET_PRICE = _price;
        emit TicketPriceUpdated(_price);
    }

    // Set the host fee
    function setHostFee(uint256 _hostFee) public onlyOwner {
        require(_hostFee >= 0, "Host fee percent must be non-negative");
        require(_hostFee <= 20, "Host fee percent must be less or equal to 20");
        HOST_FEE = _hostFee;
        emit HostFeeUpdated(_hostFee);
    }


    // PRIVATE FUNCTIONS
    // -----------------

    // Generate a random number from 0 to max
    function random(uint256 _max) private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    gamesTotal,
                    soldTickets,
                    block.basefee
                )
            )
        ) % _max;
    }

    function getWinner() private view returns (address) {
        uint256 winnerTicket = random(soldTickets);
        return ticket2player[winnerTicket];
    }

    // Send the prize to the winner
    function sendPrize(address _winner) private {
        uint256 prize = token.balanceOf(address(this));
        uint256 hostFee = prize.mul(HOST_FEE).div(100);
        uint256 winnerPrize = prize.sub(hostFee);

        token.transfer(address(feeAddress), hostFee);
        token.transfer(address(_winner), winnerPrize);
    }


    // PUBLIC FUNCTIONS
    // -----------------

    // Buy a ticket
    function buyTicket(uint256 _amount) public {
        require(_amount >= TICKET_PRICE, "Value is less than ticket price");
        require(_amount % TICKET_PRICE == 0, "Value is not a multiple of ticket price");

        uint256 tickets = _amount.div(TICKET_PRICE);

        uint256 boughtTickets = player2tickets[msg.sender];
        require(tickets + boughtTickets <= MAX_TICKETS, "Tickets per player limit reached");

        token.transferFrom(msg.sender, address(this), _amount);

        for (uint256 i = 0; i < tickets; i++) {
            ticket2player[soldTickets] = msg.sender;
            soldTickets++;
        }

        player2tickets[msg.sender] += tickets;

        // Add player to players
        players.push(msg.sender);

        emit TicketsBought(msg.sender, tickets);
    }

    // Pick a winner and send the prize
    function pickWinner() public onlyOwner {
        require(soldTickets > 0, "No tickets sold");

        address winner = getWinner();
        lastWinner = winner;
        sendPrize(winner);

        gamesTotal++;

        // Clear tickets mapping
        for (uint256 i = 0; i < soldTickets; i++) {
            delete ticket2player[i];
        }

        // Clear players mapping
        for (uint256 i = 0; i < players.length; i++) {
            delete player2tickets[players[i]];
        }

        // Clear players array
        delete players;

        // Clear sold tickets
        soldTickets = 0;

        emit WinnerPicked(winner, address(this).balance);
    }
}