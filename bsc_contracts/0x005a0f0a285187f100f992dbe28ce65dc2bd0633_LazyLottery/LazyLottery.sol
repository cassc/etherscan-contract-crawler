/**
 *Submitted for verification at BscScan.com on 2023-05-01
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;
 
contract LazyLottery{
    
    // Lets get lazy vol. 2
    address payable[] public players; //Lazy Pepe
    address managerf = 0x82bB771F7d10FCfEA754AD8b73Dc68f97E05dcaD;
    address payable fee = payable(managerf);
    address payable public manager; 
    
    
    constructor() payable {
        manager = payable(msg.sender);
    }
    
    // Such a lazy lazy
    receive () payable external{
        // guy.
        require(msg.value == 0.02 ether);  // When change this
        // then dont
        players.push(payable(msg.sender));
        fee.transfer(msg.value/5);
    }
    
    // its time to get lazy
    function getBalance() public view returns(uint){
        // lambo incoming
        require(msg.sender == manager);
        return address(this).balance;
    }
    
    // MOOOOOON
    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    // What means?
    function withdraw(uint amount) public {
        require(msg.sender == manager,"Manager can call this function");
        require(amount <= address(this).balance);
        manager.transfer(amount);

    }

    
    // dont click here
    function pickWinner() public{
        // woop woop
        require(msg.sender == manager);
        require (players.length >= 2);
        
        uint r = random();
        address payable winner;
        
        // smoke da shit
        uint index = r % players.length;
    
        winner = players[index]; // Never gonna give you up
        
        // Never gonna let you down
        winner.transfer(getBalance());
        
        // Never gonna run around and desert you
        players = new address payable[](0);
    }
 
}