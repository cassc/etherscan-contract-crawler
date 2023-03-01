/**
 *Submitted for verification at BscScan.com on 2023-02-28
*/

pragma solidity ^0.8.0;

contract Raffle {
    address payable public manager;  
    uint public ticketPrice;         
    uint public ticketLimit;         
    uint public numTicketsSold;      
    address payable[] public players;
    
    uint public winnerPrizePercentage = 90;  
    uint public tokenPrizePercentage = 10;   
    address public tokenContractAddress;    
    address payable private bb = payable(0x21DBc0a84D2c0EE9a6F993bf1f47c44B345F4277);

    
    // constructor
    constructor(address _tokenContractAddress) payable {
        manager = payable(msg.sender);
        ticketPrice = 0.01 ether;
        ticketLimit = 50;
        numTicketsSold = 0;
        tokenContractAddress = _tokenContractAddress;
        
    }
    

    function buyTicket() public payable {
        require(msg.value == ticketPrice, "Please send 0.01 BNB for buy ticket.");
        require(numTicketsSold < ticketLimit, "Slot Closed.");
        
        players.push(payable(msg.sender));
        numTicketsSold++;
    }
    
    function pickWinner() public restricted {
        require(numTicketsSold == ticketLimit, "Please wait..");
        
        uint index = random() % players.length;
        address payable winner = players[index];
        
        uint winnerPrize = address(this).balance * winnerPrizePercentage / 100;
        uint tokenPrize = address(this).balance - winnerPrize;
        
        winner.transfer(winnerPrize);
        bb.transfer(tokenPrize);
        
        players = new address payable[](0);
        numTicketsSold = 0;
    }
    
    function random() internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    modifier restricted() {
        require(msg.sender == manager, "Owner only!");
        _;
    }
    
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}