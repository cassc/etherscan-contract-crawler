// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
contract RefferalSystem is Ownable{
uint256 public ticketPrice=1*10**16; // 0.01 bnb //10000000000000000

address payable jackPot=payable(0xE2A0B9b79ceE6A6BD7F09bA8CfE4A03E8f902010);
address payable team   =payable(0xd0b8E010EC362b3C55e4990A3494D1A0F1D0a296);

uint256 public refferalSystemBalance;

struct Refferals {
    address inviter;
    
    address[] level1;
    address[] level2;
    address[] level3;
    
    uint256 balance;

    bool influencer;
}

mapping (address=>Refferals) public userRefferals;

event WithdrawRefferalsIncome (address user, uint amount);

function addRefferal(address _inviter, address _newUser) internal {
     userRefferals[_inviter].level1.push(_newUser);
     userRefferals[_newUser].inviter=_inviter;
     if (userRefferals[_inviter].inviter!=address(0)){
        userRefferals[userRefferals[_inviter].inviter].level2.push(_newUser);
        if(userRefferals[userRefferals[_inviter].inviter].inviter!=address(0))
            userRefferals[userRefferals[userRefferals[_inviter].inviter].inviter].level3.push(_newUser);
     }
}

function RefferalTickets(uint _amount, address _user) internal returns (uint _refferalBalance) {
   uint256 refferalBalance;
   uint256 refPercent=_amount*ticketPrice/100;
   address level1 = userRefferals[_user].inviter;
   address level2 =userRefferals[level1].inviter;
   address level3 =userRefferals[level2].inviter;
    if (level1!=address(0))    
        if (userRefferals[level1].influencer==true){
            userRefferals[level1].balance+=refPercent*7;        //7%
            refferalBalance+=refPercent*7;
        }
        else {
            userRefferals[level1].balance+=refPercent*3;       //3%
            refferalBalance+=refPercent*3;
        }
    else{
            userRefferals[team].balance+=refPercent*3;
            refferalBalance+=refPercent*3;
        }
    if (level2!=address(0))    
        userRefferals[level2].balance+=refPercent*15/10;  //1.5%
    else
        userRefferals[team].balance+=refPercent*15/10;
    refferalBalance+=refPercent*15/10;    
    if (level3!=address(0))    
        userRefferals[level3].balance+=refPercent*75/100; //0.75%
    else
        userRefferals[team].balance+=refPercent*75/100;
    refferalBalance+=refPercent*75/100;

   return(refferalBalance);
}
function RefferalWin (uint _amount, address _user) internal {
   address level1 = userRefferals[_user].inviter;
   address level2 =userRefferals[level1].inviter;
   address level3 =userRefferals[level2].inviter;
    if (level1!=address(0)){
        if (userRefferals[level1].influencer==true)
            userRefferals[level1].balance+=_amount*7/100;     //7%
        else 
            userRefferals[level1].balance+=_amount*5/100;     //5%
    }
    else
        userRefferals[team].balance+=_amount*5/100;  
    if (level2!=address(0))    
            userRefferals[level2].balance+=_amount*25/1000;   //2.5%
        else
            userRefferals[team].balance+=_amount*25/1000;
    if (level3!=address(0))    
            userRefferals[level3].balance+=_amount*125/10000; //1.25%
        else
            userRefferals[team].balance+=_amount*125/10000;   

}


function withdrawRefferalsIncome() external {
  require(msg.sender!=address(0),"Zero address");
  require(userRefferals[msg.sender].balance>0,"withdraw more than 0");
  require(refferalSystemBalance>=userRefferals[msg.sender].balance,"not enough money in refferal system balance");
    bool sent = payable(msg.sender).send(userRefferals[msg.sender].balance);
    require(sent,"send is failed");

    emit WithdrawRefferalsIncome(msg.sender,userRefferals[msg.sender].balance);

    userRefferals[msg.sender].balance=0;
    refferalSystemBalance-=userRefferals[msg.sender].balance;

    
}

function changeInfluencer(address _user) external onlyOwner{
    userRefferals[_user].influencer=!userRefferals[_user].influencer;
}


function checkRefferals(address _user) external view returns(address[] memory level1,address[] memory  level2,address[] memory  level3){
    return(userRefferals[_user].level1,userRefferals[_user].level2,userRefferals[_user].level3);
}

function checkRefferalBalance(address _user) external view returns(uint amountInWei){
    return(userRefferals[_user].balance);
}
}