// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "./RefferalSystem.sol";
contract Lottery is RefferalSystem{

    
    receive() external payable {
        _value+=msg.value;
    }
    

    
    uint random;

    event LotteryEndTime (uint32 ID,uint time); 
    event buyTicket      (address user, uint32 amount, uint32 ID);
    event increaseChances(address user, uint32 amount, uint32 ID);
    event newUser(address user, uint time,address inviter);
    
    uint32 public ID;
    uint  _value;
    uint  winPot;

    struct LotteryStruct {
        uint32 entrances;

        uint256 startTime;
        uint256 endTime;

        address[] members;

        address[] win1;
        address[] win10;
        address[] winTicketPriceX2;
        address[] winTicketPrice;
        address[] winHalfTicketPrice;

        uint256 pot;
        bool ended;

        mapping (address=>uint8) newMember;
        mapping (address=>uint)  chances;

        bool jackPot;
    }
    struct User{
        uint32 LotteriesAmount;
        
        uint32 lastLotteryId;
        mapping (uint32=>uint32) entrances;
        mapping (uint32=>uint) chances;
        uint32 increaseChanceTickets;
        
        uint256 balance;

        bool registred;
    }
    
    mapping (uint32 =>LotteryStruct) public LotteryId;
    mapping (address=>User)          public UserInfo;
    mapping (address=>mapping(uint32=>uint32[])) public ticketIDs; 


    function accountRegistration(address _inviter) external {
        require(_inviter!=msg.sender,"You can not set yourself as a inviter");
        require(UserInfo[msg.sender].registred==false,"Your account is already registred");
        if (_inviter!=address(0)){
            require(UserInfo[_inviter].registred==true,"Address of the inviter is not registered");
            addRefferal(_inviter,msg.sender);
        }
        UserInfo[msg.sender].registred=true;

        emit newUser(msg.sender, block.timestamp, _inviter);
    }

    function buyTickets (uint32 amount, uint32 _ID) external payable {
        require (UserInfo[msg.sender].registred==true,"Your account need to be registrated");
        require (amount>0,"Buy 1 or more tickets");
        require (msg.value==amount*ticketPrice,"not enough BNB to buy tickets");
        require (block.timestamp>LotteryId[_ID].startTime && block.timestamp<LotteryId[_ID].endTime,"Lottery didn't started or already ended");
        
        if(LotteryId[_ID].jackPot==true)
        require(UserInfo[msg.sender].LotteriesAmount>=100,"You must participate at least in 100 lottery to buy jack pot ticket");

        bool sentTeam = team.send(msg.value/5);
        require(sentTeam,"Send to team is failed");
        bool sentJackPot = jackPot.send(msg.value/5);
        require(sentJackPot,"Send to JackPot is failed");
        
        LotteryId[_ID].pot+=msg.value/2+msg.value/10;
        
        uint incChans=UserInfo[msg.sender].chances[_ID]-UserInfo[msg.sender].entrances[_ID]*100;
        
        UserInfo[msg.sender].entrances[_ID]+=amount;
        if(_ID-1==UserInfo[msg.sender].lastLotteryId)
            UserInfo[msg.sender].increaseChanceTickets=UserInfo[msg.sender].entrances[_ID-1];
        else 
            if (_ID!=UserInfo[msg.sender].lastLotteryId)
                UserInfo[msg.sender].increaseChanceTickets=0;
        UserInfo[msg.sender].lastLotteryId=_ID;
        
        
        UserInfo[msg.sender].chances[_ID]=UserInfo[msg.sender].entrances[_ID]*100+incChans;  

        uint leng=ticketIDs[msg.sender][_ID].length;
        uint32[] memory tempID = ticketIDs[msg.sender][_ID];
        ticketIDs[msg.sender][_ID]=new uint32[](amount+leng);
        if (leng>0){
            for (uint i=0;i<leng;i++){
                ticketIDs[msg.sender][_ID][i]=tempID[i];
            }
        }
        for (uint i=leng;i<ticketIDs[msg.sender][_ID].length;i++){
            LotteryId[_ID].entrances++;
            ticketIDs[msg.sender][_ID][i]=LotteryId[_ID].entrances;
        }              
        
        
        if (LotteryId[_ID].newMember[msg.sender]!=1) {
            LotteryId[_ID].members.push(msg.sender);
            LotteryId[_ID].newMember[msg.sender]=1;
            UserInfo[msg.sender].LotteriesAmount++;
        }

        uint refBalance=RefferalTickets(amount,msg.sender);
        refferalSystemBalance+=refBalance;
        LotteryId[_ID].pot-=refBalance;

        emit buyTicket (msg.sender,amount,_ID);
    }

    function increaseChance(uint32 amount, uint32 _ID) external {
        require(UserInfo[msg.sender].increaseChanceTickets>0 && amount>0,"No tickets to increase ur chance");
        require(UserInfo[msg.sender].increaseChanceTickets<=amount,"Not enough tickets");
        require(UserInfo[msg.sender].entrances[_ID]*10>=amount,"You can use only 10 increase tickets per entrances");
        require(UserInfo[msg.sender].lastLotteryId==_ID,"You should buy tickets to current lotterey");
        UserInfo[msg.sender].increaseChanceTickets-=amount;
        UserInfo[msg.sender].chances[_ID]+=amount*5;

        emit increaseChances(msg.sender,amount,_ID);
    }
    
    function setLottery (uint256 _startTime,uint256 _endTime) external onlyOwner {
        require(_endTime>_startTime,"Lottery's start time is more than end time");
        ID++;
        LotteryId[ID].startTime=block.timestamp+_startTime;
        LotteryId[ID].endTime=block.timestamp+_endTime;
    } 

    uint   totalchances;
    uint32 tenPercent;
    uint32 fifteenPercent;

    function endLottery(uint32 _ID) external onlyOwner {
        require(LotteryId[_ID].endTime<=block.timestamp,"Lottery is still running");
        require(LotteryId[_ID].ended==false,"The winners have already been chosen");
        if(LotteryId[_ID].members.length>0){
                winPot=0;
                for(uint32 i=0;i<LotteryId[_ID].members.length;i++){
                    if (i>0)
                    LotteryId[_ID].chances[LotteryId[_ID].members[i]]=UserInfo[LotteryId[_ID].members[i]].chances[_ID]+LotteryId[_ID].chances[LotteryId[_ID].members[i-1]];
                    else
                    LotteryId[_ID].chances[LotteryId[_ID].members[i]]=UserInfo[LotteryId[_ID].members[i]].chances[_ID];
                }
            totalchances  = LotteryId[_ID].chances[LotteryId[_ID].members[LotteryId[_ID].members.length-1]];
            tenPercent    = LotteryId[_ID].entrances/10;
            fifteenPercent= LotteryId[_ID].entrances/7;
            
            uint win1 =(LotteryId[_ID].pot/10);
            uint win10=(LotteryId[_ID].pot/50);
            uint win10P=(ticketPrice);
            uint win15P=ticketPrice/2;   
            uint win10p=ticketPrice/4; 

            if(LotteryId[_ID].jackPot)
                setWinner(1,_ID,LotteryId[_ID].pot,1);
            else{
                setWinner(1,_ID,win1,1);
                setWinner(10,_ID,win10,2);
                setWinner(tenPercent,_ID,win10P,3);
                setWinner(fifteenPercent,_ID,win15P,4); 
                setWinner(tenPercent,_ID,win10p,5);
            }
            if(LotteryId[_ID].pot-winPot>0)
                refundSurplus(LotteryId[_ID].pot-winPot,_ID);
            if(LotteryId[_ID].pot-winPot>0)
                _value+=LotteryId[_ID].pot-winPot;
        }
       LotteryId[_ID].ended=true;

       emit LotteryEndTime(_ID,block.timestamp);
    }
    
    function setWinner (uint _amount, uint32 _id,uint _win, uint8 _nmb) internal {
        for (uint32 i=0;i<_amount;i++) {
          random=randomN(totalchances)+1;
          uint lastTicket;
          for (uint a=0;a<LotteryId[_id].members.length;a++){
              if (random>lastTicket && random<=LotteryId[_id].chances[LotteryId[_id].members[a]]){
                  if (_nmb==1)
                    LotteryId[_id].win1.push(LotteryId[_id].members[a]);
                  if (_nmb==2)
                    LotteryId[_id].win10.push(LotteryId[_id].members[a]);
                  if (_nmb==3)
                    LotteryId[_id].winTicketPriceX2.push(LotteryId[_id].members[a]);
                  if (_nmb==4)
                    LotteryId[_id].winTicketPrice.push(LotteryId[_id].members[a]);
                  if (_nmb==5)
                    LotteryId[_id].winHalfTicketPrice.push(LotteryId[_id].members[a]);
                    
                  if(userRefferals[userRefferals[LotteryId[_id].members[a]].inviter].influencer==true){
                    UserInfo[LotteryId[_id].members[a]].balance+=_win-(_win*1075/10000);
                    refferalSystemBalance+=_win*1075/10000;
                  }
                  else{
                    UserInfo[LotteryId[_id].members[a]].balance+=_win-(_win*875/10000);
                    refferalSystemBalance+=_win*875/10000;
                  }

                  RefferalWin(_win,LotteryId[_id].members[a]);
                  winPot+=_win;

                  if (UserInfo[LotteryId[_id].members[a]].entrances[_id]>0)
                      UserInfo[LotteryId[_id].members[a]].entrances[_id]--;
                  break;
              }
              lastTicket=LotteryId[_id].chances[LotteryId[_id].members[a]];
          }
        }
    }
    
    function refundSurplus(uint amount, uint32 _ID) internal {
        uint valuePerWinner = amount/11;
        UserInfo[LotteryId[_ID].win1[0]].balance+=valuePerWinner;
        for (uint8 i=0;i<10;i++){
            UserInfo[LotteryId[_ID].win10[i]].balance+=valuePerWinner;
        }
        winPot+=amount;
    }

    function withdraw() external {
        require(msg.sender!=address(0),"Zero address");
        require(UserInfo[msg.sender].balance>0,"Withdraw more than 0");
        bool _sent=payable(msg.sender).send(UserInfo[msg.sender].balance);
        require(_sent,"Send is failed");
        UserInfo[msg.sender].balance=0;
    }

    function setJackPot(uint32 _ID) external payable {
        require(msg.sender==jackPot,"Msg.sender is not jack pot wallet");
        require(LotteryId[_ID].ended==false,"Lottery is over");
        require(LotteryId[_ID].startTime>0,"Lottery not running");
        LotteryId[_ID].jackPot=true;
        LotteryId[_ID].pot+=msg.value;
    }

    function changeTicketPrice(uint _amount) external onlyOwner {
        ticketPrice=_amount;
    }

    function changeTeamAddress(address _team) external onlyOwner {
        team=payable(_team);
    }

    function changeJackPotAddress(address _jackPot) external onlyOwner {
        jackPot=payable(_jackPot);
    }

    function changeEndTimeLottery(uint256 _endTime, uint32 _ID) external onlyOwner {
        require(LotteryId[_ID].ended==false,"Lottery is over");
        require(LotteryId[_ID].startTime>0,"Lottery not running");
        LotteryId[_ID].endTime=block.timestamp+_endTime;
    }

    function receiveWithdraw() external onlyOwner {
       require(_value>0,"Nothing to withdraw"); 
       bool sent=payable(msg.sender).send(_value);
       require(sent,"Send is failed");
    }

     function checkWinners(uint32 _ID) external view returns (address[] memory win1,address[] memory win10,address[] memory winTicketX2,address[] memory winTicket,address[] memory winHalfTicket){
        return (LotteryId[_ID].win1,LotteryId[_ID].win10,LotteryId[_ID].winTicketPriceX2,LotteryId[_ID].winTicketPrice,LotteryId[_ID].winHalfTicketPrice);
    }

    function checkRegistration(address _user) public view returns (bool) {
        return UserInfo[_user].registred;
    }

    function checkActiveLottery () external view returns (uint32[] memory Id) {
        uint32[] memory _IDs = new uint32[](ID);
        uint32 n;
        for (uint32 i=1;i<ID+1;i++){
            if (LotteryId[i].ended==false && LotteryId[i].endTime>block.timestamp) {
                _IDs[n]=i;
                n++;
            }
        }
        uint32[] memory IDs = new uint32[](n);
        for (uint32 i=0;i<n;i++){
            IDs[i]=_IDs[i];
        }
        return IDs;
    }

    uint cnt;
    
    function randomN(uint num) private returns(uint){
        cnt++;
        return uint(keccak256(abi.encodePacked(block.timestamp,cnt, 
        msg.sender))) % num;
    }

    function checkTicketIDs(address user,uint32 _ID) external view returns (uint32[] memory ticketID) {
        return(ticketIDs[user][_ID]);
    }

    function checkIncreaseChances(address user) external view returns (uint32 IncreaseTickets) {
        return(UserInfo[user].increaseChanceTickets);
    }

    function checkJackPotAddress() external view returns (address JackPot) {
        return(jackPot);
    }

      function VerifyMessage(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }
}