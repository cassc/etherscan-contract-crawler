/**
 *Submitted for verification at Etherscan.io on 2023-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PremiumReserve {
    
    modifier ownerOnly {
    require(msg.sender == owner, "Only the contract owner can call this function");
    _;
}

      constructor(address _team1, address _team2, address _team3, address _team4, uint256 price) {
        team1 = payable(_team1);
        team2 = payable(_team2);
        team3 = payable(_team3);
        team4 = payable(_team4);
        owner = payable(msg.sender);
        PremiumPrice = price;
        
    }
     event Transfer(address indexed from, address indexed to, uint256 value);

    address payable private team1;
    address payable private team2;
    address payable private team3;
    address payable private team4;
    address private owner;
    
    uint256 public PremiumPrice;
    uint internal totalReserved;
    uint public uniqueUsers;
    uint internal maxReserves = 487;
    bool public reserveOn;
    mapping(address => uint256) internal reserved;
    mapping(address => bool) internal canReserve;

    function start() public ownerOnly{
        reserveOn = true;


    }


    function end() public ownerOnly{
        reserveOn = false;


    }

   function ReserveImmortal(uint256 amount) public payable {
    require(reserveOn, "Reserve has not started yet.");
    require(canReserve[msg.sender], "Not Eligible");
    require(reserved[msg.sender] + amount <= 2, "User Max Reserved");
    require(totalReserved + amount <= maxReserves, "Max Reserved");
    require(msg.value == (PremiumPrice * amount), "Insufficient Funds");
    
    if(reserved[msg.sender] == 0) {
        uniqueUsers++;

    }
    
    reserved[msg.sender] += amount;
    totalReserved += amount;
    emit Transfer(address(0), msg.sender, amount);
}   
    function name() public view virtual returns (string memory) {
        return "Immortal Reserve";
    }

    function symbol() public view virtual returns (string memory) {
        return "IR";
    }

    function getReserved(address user) public view returns (uint256) {
        return reserved[user];
    }
    
     function isAllowed(address user) public view returns (bool) {
        return canReserve[user];
    }

    function getTotalReserved() public view returns (uint256) {
        return totalReserved;
    }
    
    function addToCanReserve(address user) internal {
        canReserve[user] = true;
    }
    
    function addMultipleToCanReserve(address[] memory users) public ownerOnly  {
        for (uint256 i = 0; i < users.length; i++) {
            addToCanReserve(users[i]);
        }
    }

    function withdraw() public ownerOnly {
        require(address(this).balance > 0, "No funds to withdraw");

        uint256 totalBalance = address(this).balance;
        uint256 team1Share = (totalBalance * 64) / 100;
        uint256 team2Share = (totalBalance * 20) / 100;
        uint256 team3Share = (totalBalance * 10) / 100;
        uint256 team4Share = (totalBalance * 6) / 100;

        team1.transfer(team1Share);
        team2.transfer(team2Share);
        team3.transfer(team3Share);
        team4.transfer(team4Share);
    }

    
}