/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.15;

interface IERC20 {
    // mind the `view` modifier
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BGLLottery{
    //State /Storage Variable
    address public owner;
    address public token;
    address public daoModule;
    address payable[] public players;
    address[] public winners;
    uint public lotteryId;

    constructor(){
        owner= msg.sender;
        lotteryId = 0;
        token = 0x2bA64EFB7A4Ec8983E22A49c81fa216AC33f383A; // WBGL token
        daoModule = 0xa7B8d36708604c46dc896893ea58357A975d6E6b; // Execute proposals via https://snapshot.org/#/bgldao.eth
    }

    //Enter Function to enter in lottery
    function enter()public payable{
        require(IERC20(token).balanceOf(msg.sender) >= 50*10**18, "Insufficient Balance");
        IERC20(token).transferFrom(msg.sender, address(this), 50*10**18);
        players.push(payable(msg.sender));
    }

    //Get Players
    function  getPlayers() public view returns(address payable[] memory){
        return players;
    }

    //Get Balance 
    function getbalance() public view returns(uint){
        return IERC20(token).balanceOf(address(this));
    }
     
    //Get Lottery Id
    function getLotteryId() public view returns(uint){
        return lotteryId;
    }
    
    //Get a random number (helper function for picking winner)
    function getRandomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(owner,block.timestamp)));
    }

    //Pick Winner
    function pickWinner() public onlyOwner{
        uint randomIndex =getRandomNumber()%players.length;
        IERC20(token).transfer(players[randomIndex], getbalance());
        winners.push(players[randomIndex]);
        //Current lottery done
        lotteryId++;
        //Clear the player array
        players =new address payable[](0);
    }
  
    function getWinners() public view returns(address[] memory){
        return winners;
    }

    modifier onlyOwner(){
        require(msg.sender == owner || msg.sender == daoModule,"Only owner or DAO have control");
        _;
    }


}