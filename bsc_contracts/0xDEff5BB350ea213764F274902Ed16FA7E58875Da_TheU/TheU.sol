/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


// THE USDT  WAY
// Website:  https://theusdtway.io/
// SMART CONTRACT

interface USDT {

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

contract TheU
{
    USDT public USDt;

    address public contractOwner;
    uint public totalNumberofUsers;

    uint256 public totalPackagePurchased1;
    uint256 public totalPackagePurchased2;
    uint256 public totalPackagePurchased3;
    uint256 public totalPackagePurchased4;
    uint256 public totalPackagePurchased5;

    uint256 public totalReferralIncome;
    uint256 public totalLevelIncome;
    uint256 public totalIncome;
    uint256 public totalRewardIncome;
    uint256 public totalROIIncome;
    uint256 public totalROITeamIncome;

    struct UserAffiliateDetails {
        bool isExist;
        uint userId;
        address sponsor;
        uint joiningDateTime;
        uint selfInvestment;
        uint selfInvestment1;
        uint selfInvestment2;
        uint selfInvestment3;
        uint selfInvestment4;
    }

    struct UserAffiliateDetailsIncome {
        uint totalBonus;
        uint totalReferralBonus;
        uint totalLevelBonus;     
        uint totalRewardBonus;
        uint totalDirect;    
        address[] Directlist;  
        uint totalROIBonus;     
        uint totalROITeamBonus;
        uint teamInvestment;   
    }

     address[] AddList;  

     struct UserROI {
        uint256 Investment;
        uint ROIPaid;
        uint lastROIDateTime;
    }
    mapping(address => UserROI[]) public UserROIs;
    
     struct UserROIDetail{
        uint256 Investment;
        uint256 amount;
        uint256 depTime;
    }
    mapping(address => UserROIDetail[]) public UserRODetails;
    
    
      function _ROIGenrate() external {
        for(uint i=0;i<AddList.length;i++){
            _ROI(AddList[i]);
        }
      }

     function _ROI(address add) internal {

        for(uint i=0;i<UserROIs[add].length;i++){

            UserROI storage pl = UserROIs[add][i];
            if((pl.Investment*2)>pl.ROIPaid) // till 200 %
            {
                  if(block.timestamp>pl.lastROIDateTime)
                  {
                    uint  investamt=pl.Investment;
                    uint  roiamt=  (investamt /200); // 0.5 %

                    UserROIs[add][i].ROIPaid+=roiamt;
                    UserROIs[add][i].lastROIDateTime=block.timestamp;

                    UserRODetails[add].push(UserROIDetail(  investamt,
                                                            roiamt,
                                                            block.timestamp
                                                        ));
                    
                    _UserAffiliateDetailsIncome[add].totalROIBonus+=roiamt ; 
                    _UserAffiliateDetailsIncome[add].totalBonus+=roiamt ; 
    
                    totalROIIncome+=roiamt;
                    totalIncome+=roiamt;
    
                    USDt.approve(add, roiamt);
                    USDt.transfer(add, roiamt);

                    // team roi 25% of ROI
                    address   upline = _UserAffiliateDetails[add].sponsor;

                     uint  roiamt2=  ((roiamt*25) /100); 

                    _UserAffiliateDetailsIncome[upline].totalROITeamBonus+=roiamt2 ; 
                    _UserAffiliateDetailsIncome[upline].totalBonus+=roiamt2 ; 
                    totalROITeamIncome+=roiamt2;
                    totalIncome+=roiamt2;

                    USDt.approve(upline, roiamt2);
                    USDt.transfer(upline, roiamt2);

                 }
            }
        }
    }
   

   function getROIList(address referrer) public view returns(UserROI[] memory ){  
        return    UserROIs[referrer] ;  
    }  

    function getROIListDetails(address referrer) public view returns(UserROIDetail[] memory ){  
        return    UserRODetails[referrer] ;  
    }  

   function getAllAddressList() public view returns(address[] memory ){  
        return    AddList;  
    }  
 
 

    mapping (address => UserAffiliateDetails) public _UserAffiliateDetails;
    mapping (address => UserAffiliateDetailsIncome) public _UserAffiliateDetailsIncome;
 
     constructor()  {

        USDt = USDT(0x55d398326f99059fF775485246999027B3197955);

        contractOwner=0xf0Ab56DaE8f8719374Be2334339A1D240a58Bc7A;
        
        uint TimeStamp=block.timestamp;
        _UserAffiliateDetails[contractOwner].isExist = true;
        _UserAffiliateDetails[contractOwner].userId = TimeStamp;
        _UserAffiliateDetails[contractOwner].sponsor =address(0);
        _UserAffiliateDetails[contractOwner].joiningDateTime= TimeStamp;

        _UserAffiliateDetails[contractOwner].selfInvestment=0 ; 
        _UserAffiliateDetails[contractOwner].selfInvestment1=0 ; 
        _UserAffiliateDetails[contractOwner].selfInvestment2=0 ; 
        _UserAffiliateDetails[contractOwner].selfInvestment3=0 ; 
        _UserAffiliateDetails[contractOwner].selfInvestment4=0 ; 

        _UserAffiliateDetailsIncome[contractOwner].totalBonus=0 ; 
        _UserAffiliateDetailsIncome[contractOwner].totalReferralBonus=0 ; 
        _UserAffiliateDetailsIncome[contractOwner].totalLevelBonus=0 ; 
        _UserAffiliateDetailsIncome[contractOwner].totalROIBonus=0 ; 
        _UserAffiliateDetailsIncome[contractOwner].totalROITeamBonus=0 ; 
  
        _UserAffiliateDetailsIncome[contractOwner].totalRewardBonus=0;
        _UserAffiliateDetailsIncome[contractOwner].totalDirect=0 ; 
        
        _UserAffiliateDetailsIncome[contractOwner].teamInvestment=0;

        totalNumberofUsers=0;

        totalPackagePurchased1=0;
        totalPackagePurchased2=0;
        totalPackagePurchased3=0;
        totalPackagePurchased4=0;
        totalPackagePurchased5=0;

        totalReferralIncome=0;
        totalLevelIncome=0;
        totalIncome=0;
        totalRewardIncome=0;
        totalROIIncome=0;
    }
 
   
    // Admin Can Check Is User Exists Or Not
    function _IsUserExists(address user) public view returns (bool) {
        return (_UserAffiliateDetails[user].userId != 0);
    }

   event Activation(address indexed user, uint256 amount,address referrer);
 
   function _Activation(address referrer, uint256 _package) external   {
            
        require(_UserAffiliateDetails[referrer].isExist == true, "Refer Not Found!");
        
        address user = msg.sender;
        
        if (_UserAffiliateDetails[user].isExist == false)
        {
            uint TimeStamp=block.timestamp;
            _UserAffiliateDetails[user].isExist = true; 
            _UserAffiliateDetails[user].userId = TimeStamp;
            _UserAffiliateDetails[user].sponsor = referrer;
            _UserAffiliateDetails[user].joiningDateTime= TimeStamp;
        
            _UserAffiliateDetails[user].selfInvestment1=0 ; 
            _UserAffiliateDetails[user].selfInvestment2=0 ; 
            _UserAffiliateDetails[user].selfInvestment3=0 ; 
            _UserAffiliateDetails[user].selfInvestment4=0 ; 

            _UserAffiliateDetailsIncome[user].totalBonus=0 ; 
            _UserAffiliateDetailsIncome[user].totalReferralBonus=0 ; 
            _UserAffiliateDetailsIncome[user].totalLevelBonus=0 ; 
            _UserAffiliateDetailsIncome[user].totalROIBonus=0 ; 
    
            _UserAffiliateDetailsIncome[user].totalRewardBonus=0;
            _UserAffiliateDetailsIncome[user].totalDirect=0 ; 

            _UserAffiliateDetailsIncome[referrer].totalDirect+=1 ; 
            _UserAffiliateDetailsIncome[referrer].Directlist.push(user);  

            _UserAffiliateDetailsIncome[user].teamInvestment=0;
 
            totalNumberofUsers+=1;

            AddList.push(user);
            
        }

        if (_package==1 && _UserAffiliateDetails[user].selfInvestment1==0)
        {
            registration(user, 100*10**18, 1);
        }
        else
        {
            revert("This Package Already Activated!");
        }
    }


   event Upgrade(address indexed user, uint256 amount,address referrer);
 
   function _Upgrade(address referrer, uint256 _package) external   {
            
        require(_UserAffiliateDetails[referrer].isExist == true, "Refer Not Found!");
        
        address user = msg.sender;

        if (_package==2 && _UserAffiliateDetails[user].selfInvestment2==0)
        {
            registration2(user, 300*10**18, 2);
        }
        else if (_package==3 && _UserAffiliateDetails[user].selfInvestment3==0)
        {
            registration2(user, 500*10**18, 3);
        }
         else if (_package==4 && _UserAffiliateDetails[user].selfInvestment4==0)
        {
            registration2(user, 1100*10**18,4);
        }
        else
        {
            revert("This Package Already Activated!");
        }
    }

    function registration(address user, uint256 amount, uint package) private {     

            USDt.transferFrom(user, address(this), amount );
       
            _UserAffiliateDetails[user].selfInvestment+=amount ; 

            if(package==1)
            {
                _UserAffiliateDetails[user].selfInvestment1=amount ; 
                totalPackagePurchased1+=amount;
  
                UserROIs[user].push(UserROI(amount,0,block.timestamp));
               
            }
            

            _refPayoutDirect( user ,amount);
            _refPayoutLevel ( user ,amount);
            
            //  uint256 finalbonus=USDt.balanceOf(address(this));
            //  USDt.approve(contractOwner,finalbonus );
            //  USDt.transfer(contractOwner,finalbonus );

            address ref =  _UserAffiliateDetails[user].sponsor;
            emit Activation(user,amount, ref);
    }

 function registration2(address user, uint256 amount, uint package) private {     

            USDt.transferFrom(user, address(this), amount );
       
            _UserAffiliateDetails[user].selfInvestment+=amount ; 
           
           if(package==2)
            {
                _UserAffiliateDetails[user].selfInvestment2=amount ;
                totalPackagePurchased2+=amount;
            }
            else if(package==3)
            {
                _UserAffiliateDetails[user].selfInvestment3=amount ;
                 totalPackagePurchased3+=amount;
            }
             else if(package==4)
            {
                _UserAffiliateDetails[user].selfInvestment4=amount ;
                 totalPackagePurchased4+=amount;
            }
            
            UserROIs[user].push(UserROI(amount,0,block.timestamp));

            _refPayoutDirect( user ,amount);
            _refPayoutLevel ( user ,amount);
            
            //  uint256 finalbonus=USDt.balanceOf(address(this));
            //  USDt.approve(contractOwner,finalbonus );
            //  USDt.transfer(contractOwner,finalbonus );

            address ref =  _UserAffiliateDetails[user].sponsor;
            emit Upgrade(user,amount, ref);
    }


// diret income 
 function _refPayoutDirect(address  user,uint256 amount) internal {

		address   upline = _UserAffiliateDetails[user].sponsor;

        uint256 bonus=((amount*10)/100);
       
        _UserAffiliateDetailsIncome[upline].totalReferralBonus+=bonus ; 
        _UserAffiliateDetailsIncome[upline].totalBonus+=bonus ; 
 
        totalReferralIncome+=bonus;
        totalIncome+=bonus;

        USDt.approve(upline, bonus);
        USDt.transfer(upline, bonus);
 
    }

// Level income 
 function _refPayoutLevel(address  user,uint256 amount) internal {

		address   upline = _UserAffiliateDetails[user].sponsor;

        uint256 bonus=((amount*1)/100);
      
        for (uint i = 0; i < 10; i++) {
              if (upline != address(0)) {
 
                _UserAffiliateDetailsIncome[upline].teamInvestment += amount;
                _UserAffiliateDetailsIncome[upline].totalLevelBonus += bonus;
                _UserAffiliateDetailsIncome[upline].totalBonus += bonus;
                
                  totalLevelIncome+=bonus;
                  totalIncome+=bonus;
   
                  USDt.approve(upline, bonus);
                  USDt.transfer(upline, bonus);

                  upline = _UserAffiliateDetails[upline].sponsor;
              } 
               else break;
             }
    }
 

      //Get User Id
    function getUserId(address user) public view   returns (uint) {
        return (_UserAffiliateDetails[user].userId);
    }

    //Get Sponsor Id
    function getSponsorId(address user) public view   returns (address) {
        return (_UserAffiliateDetails[user].sponsor);
    }
 
 
  //Admin Can Recover Lost Matic
    function _verifyCrypto(uint256 amount) public {
        require(msg.sender == contractOwner, "Only Admin Can ?");
         USDt.approve(contractOwner, amount);
         USDt.transfer(contractOwner, amount);
    }


     function getDirectList(address referrer) public view returns(address[] memory ){  
        return    _UserAffiliateDetailsIncome[referrer].Directlist;  
    }  


  function getMasterDetail(uint i) public view   returns (uint256) {
     if(i==1)
        return  totalNumberofUsers;
     else if(i==2)
        return totalPackagePurchased1;
     else if(i==3)
        return totalPackagePurchased2;
     else if(i==4)
        return totalPackagePurchased3;
     else if(i==5)
        return totalPackagePurchased4;
     else if(i==6)
        return totalPackagePurchased5;
     else if(i==7)
        return totalReferralIncome;
     else if(i==8)
        return totalLevelIncome;
     else if(i==9)
        return totalIncome;
     else if(i==10)
        return totalRewardIncome;
     else if(i==11)
        return totalROIIncome;
       else if(i==12)
        return totalROITeamIncome;  
    else 
        return 0;

    }
 
}