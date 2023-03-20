/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface DUSD{
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) ;
}





contract ESEVVENStaking
    {
       
        address  public owner;

        

        
        address MSDTcontract=0x49AEF9F609F759c1180E79E61691BB9785ae8e15;

        uint public totalDUSDInvestors;
        uint public rewardToken=4000000000000000000;//50000000
        //uint public min_Stake_amount=10000;  //10000000000000000000000
        uint public min_Stake_amount=1;  //10000000000000000000000

        uint public max_Stake_amount=5000000; //5000000000000000000000000
        uint public denomenator=100000; //5000000000000000000000000
        uint public investmentPeriod=300 days;
        uint public totalbusiness; 
        uint rew_till_done;


        struct allInvestments{

            uint investedAmount;
            uint withdrawnTime;
            uint DepositTime;
            uint investmentNum;
            uint unstakeTime;
            bool unstake;
        }

        struct ref_data{
            uint reward;
            uint count;
        }

        struct Data{

            mapping(uint=>allInvestments) investment;
            address[] hisReferrals;
            address referralFrom;
            mapping(uint=>ref_data) referralLevel;
            uint reward;
            uint noOfInvestment;
            uint totalInvestment;
            uint totalWithdraw_reward;
            bool investBefore;
            uint stakeTime;
        }
  
        mapping(address=>Data) public DUSDinvestor;

        constructor(){
            
            owner=msg.sender;              //here we are setting the owner of this contract

        }

        function Stake(uint _investedamount) external returns(bool success){
            require(_investedamount >= min_Stake_amount && _investedamount <= max_Stake_amount,"value is not greater than 1 and less than 5000000");     //ensuring that investment amount is not less than zero
            
            if(DUSDinvestor[msg.sender].investBefore == false)
            { 
                totalDUSDInvestors++;                                     
            }
            if(DUSDinvestor[msg.sender].totalInvestment == 0)
            { 
                DUSDinvestor[msg.sender].stakeTime = block.timestamp + 300 days;
            }

            uint num = DUSDinvestor[msg.sender].noOfInvestment;
            DUSDinvestor[msg.sender].investment[num].investedAmount =_investedamount;
            DUSDinvestor[msg.sender].investment[num].DepositTime=block.timestamp;
            DUSDinvestor[msg.sender].investment[num].withdrawnTime=block.timestamp + investmentPeriod ;  // 300 days
            DUSDinvestor[msg.sender].investment[num].investmentNum=num;
            DUSDinvestor[msg.sender].totalInvestment+=_investedamount;
            DUSDinvestor[msg.sender].noOfInvestment++;
            totalbusiness+=_investedamount;
            DUSD(MSDTcontract).transferFrom(msg.sender,address(this),_investedamount*10**18);
            DUSDinvestor[msg.sender].investBefore=true;

            return true;
            
        }
        function getReward() view public returns(uint){ //this function is get the total reward balance of the investor
            uint totalReward;
            uint depTime;
            uint rew;
            uint temp = DUSDinvestor[msg.sender].noOfInvestment;
            for( uint i = 0;i < temp;i++)
            {   
                if(!DUSDinvestor[msg.sender].investment[i].unstake)
                {
                    depTime =block.timestamp - DUSDinvestor[msg.sender].investment[i].DepositTime;
                }
                else{
                    depTime =DUSDinvestor[msg.sender].investment[i].unstakeTime - DUSDinvestor[msg.sender].investment[i].DepositTime;
                }
                depTime=depTime/1; //1 second
                if(depTime>0)
                {
                    //rew  = ((DUSDinvestor[msg.sender].investment[i].investedAmount)*rewardToken)/denomenator;
                    rew  = ((DUSDinvestor[msg.sender].investment[i].investedAmount)*rewardToken)/(denomenator*86400);

                    totalReward += depTime * rew;
                }
            }
            totalReward -= DUSDinvestor[msg.sender].totalWithdraw_reward;

            return totalReward;
        }

        

        function withdrawReward() external returns (bool success){
            uint Total_reward = getReward();
            require(Total_reward>0,"you dont have rewards to withdrawn");         //ensuring that if the investor have rewards to withdraw
            DUSDinvestor[msg.sender].totalWithdraw_reward+=Total_reward;
            DUSD(MSDTcontract).transfer(msg.sender, Total_reward);
            return true;

        }


        function unStake() external  returns (bool success){
            require(DUSDinvestor[msg.sender].totalInvestment>0,"you dont have investment to withdrawn");             //checking that he invested any amount or not
            uint amount=DUSDinvestor[msg.sender].totalInvestment;
            uint temp = DUSDinvestor[msg.sender].noOfInvestment;
            uint from = rew_till_done;
            //uint amount50;
            //uint amount50;
            if(DUSDinvestor[msg.sender].stakeTime > block.timestamp)
            {
                //amount50 = (amount*50)/100;
                //amount70 = (amount*70)/100;
                DUSD(MSDTcontract).transfer(msg.sender,amount * 10**18);             //transferring this specific investment to the investor
                //DUSD(MSDTcontract).transfer(fee_receiver,amount50 * 10**18);   

            }
            else{

                DUSD(MSDTcontract).transfer(msg.sender,amount* 10**18);             //transferring this specific investment to the investor
            }
            for( from=0;from < temp;from++)
            {   
                DUSDinvestor[msg.sender].investment[from].unstake =true;    
                DUSDinvestor[msg.sender].investment[from].unstakeTime =block.timestamp;    

                            

            }
            rew_till_done =DUSDinvestor[msg.sender].noOfInvestment;                                       
            DUSDinvestor[msg.sender].totalInvestment=0;           // decrease this invested amount from the total investment

            return true;

        }

        function getTotalInvestmentDUSD() public view returns(uint) {   //this function is to get the total investment of the ivestor
            
            return DUSDinvestor[msg.sender].totalInvestment;

        }

        function getAllDUSDinvestments() public view returns (allInvestments[] memory) { //this function will return the all investments of the investor and withware date
            uint num = DUSDinvestor[msg.sender].noOfInvestment;
            uint temp;
            uint currentIndex;
            
            for(uint i=0;i<num;i++)
            {
               if( DUSDinvestor[msg.sender].investment[i].investedAmount > 0 ){
                   temp++;
               }

            }
         
            allInvestments[] memory Invested =  new allInvestments[](temp) ;

            for(uint i=0;i<num;i++)
            {
               if( DUSDinvestor[msg.sender].investment[i].investedAmount > 0 ){
                 //allInvestments storage currentitem=DUSDinvestor[msg.sender].investment[i];
                   Invested[currentIndex]=DUSDinvestor[msg.sender].investment[i];
                   currentIndex++;
               }

            }
            return Invested;

        }



        function DUSDTotalReferrals() public view returns(uint){ // this function is to get the total number of referrals 
            return (DUSDinvestor[msg.sender].hisReferrals).length;
        }

        function DUSDReferralsList() public view returns(address[] memory){ //this function is to get the all investors list with there account number
           return DUSDinvestor[msg.sender].hisReferrals;
        }
        function setReward(uint _amount,uint _denomenator) public 
        {
            rewardToken = _amount;
            denomenator = _denomenator;

        }
        function set_min_Stake_amount(uint _amount) public 
        {
            min_Stake_amount = _amount;
        }
        function set_max_Stake_amount(uint _amount) public 
        {
            max_Stake_amount = _amount;
        }
        function set_values(uint min_stake,uint max_stake,uint reward_per_day,uint _denomenator) public 
        {
            max_Stake_amount = max_stake;
            min_Stake_amount = min_stake;
            rewardToken = reward_per_day;
            denomenator = _denomenator;
        }
        function transferOwnership(address _owner)  public
        {
            require(msg.sender==owner,"only Owner can call this function");
            owner = _owner;
        }

        



    }