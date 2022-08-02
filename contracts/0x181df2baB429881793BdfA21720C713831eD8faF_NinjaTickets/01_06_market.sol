// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NinjaTickets is Ownable {
    string constant version = 'v2.0.0';
    IERC20 public StealthToken;

    mapping(uint256 => ticket) public IdToTicket;
    mapping(uint256 => address[]) public IdToUsers;

    struct ticket {
        string name;
        uint256 cost;
        uint256 id;
        uint256 totalSupply;
        uint256 maxSupply;
    }

    constructor(address _tokenContract) {
        StealthToken = IERC20(_tokenContract);
    }

    function addTicket(ticket memory _ticket) public onlyOwner {
        require(IdToTicket[_ticket.id].maxSupply == 0, "Ticket already exists");
        require(_ticket.maxSupply > 0, "Max supply should be grater than 0");
        IdToTicket[_ticket.id] = _ticket;
    }

    function buyTicket(uint256 ticketId) public {
        require(IdToTicket[ticketId].totalSupply < IdToTicket[ticketId].maxSupply, "Max supply reached");

        uint256 allowance = StealthToken.allowance(msg.sender, address(this));
        require(allowance >= IdToTicket[ticketId].cost, "Check the token allowance");
        require(StealthToken.transferFrom(msg.sender, address(this), IdToTicket[ticketId].cost), "Failed to send");

        IdToTicket[ticketId].totalSupply += 1;
        IdToUsers[ticketId].push(msg.sender);
    }

    function buyMultipleTickets(uint256 ticketId,uint256 amount) public {
        require(IdToTicket[ticketId].maxSupply != 0, "Ticket doesn't exists");
        require(0 < amount, "Max supply should be greater than 0");
        require(IdToTicket[ticketId].totalSupply < IdToTicket[ticketId].maxSupply, "Max supply reached");
        require(IdToTicket[ticketId].totalSupply + amount < IdToTicket[ticketId].maxSupply, "Entered amount exceeds max supply");

        uint256 allowance = StealthToken.allowance(msg.sender, address(this));
        require(allowance >= IdToTicket[ticketId].cost * amount, "Check the token allowance");
        require(StealthToken.transferFrom(msg.sender, address(this), IdToTicket[ticketId].cost * amount), "Failed to send");
        IdToTicket[ticketId].totalSupply += amount;

        uint i = 0;
        while (i < amount) {
            IdToUsers[ticketId].push(msg.sender);
            i++;
        }
    }

    function changeMaxSupply(uint256 ticketId, uint256 amount) public onlyOwner {
        require(IdToTicket[ticketId].totalSupply < amount, "Cant reduce below than total supply");
        IdToTicket[ticketId].maxSupply = amount;
    }

    function getUsers(uint256 ticketId) public view returns (address[] memory) {
        return IdToUsers[ticketId];
    }

    function removeUsers(uint256 ticketId) public onlyOwner {
        delete IdToUsers[ticketId];
    }

    function tokenWithdraw() public onlyOwner {
        uint256 balance = StealthToken.balanceOf(address(this));
        StealthToken.transfer(msg.sender, balance);
    }
}