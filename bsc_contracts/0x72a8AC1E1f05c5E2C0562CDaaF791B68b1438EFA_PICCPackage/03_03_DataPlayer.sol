pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed

import "./Base.sol";

    using SafeMath for uint;

contract DataPlayer is Base{
        struct InvestInfo {
            uint256 id; 
            uint256 amount; 
            uint256 settlementTime; 
             uint256 endTime;
        }

        struct Player{
            uint256 id; 
            address addr; 
            uint256 MiningIncome; 
            InvestInfo[] list; 
            uint256 AllInvestInfo; 

        }



 


    mapping(address => mapping(uint256 => uint256)) public PlayerPackage; 


    mapping(uint256 => uint256)  public PackagePrice;
    mapping(uint256 => uint256)  public Packageshare;



    mapping(uint256 => uint256)  public PackagePI_Limit;


    mapping(uint256 => uint256)  public PackageCC_Limit;


    uint256 public PICC_Limit; 
    uint256 public PI_Limit; 
    uint256 public CC_Limit; 

    uint256 public PICCLimitAll; 


 
     mapping(address => Player) public _player; 


    address public ProjectPartyWallet = 0x56fb9f39A9bD281CA216105ac40B99D4D7f3FcB8; 

    address public RewardWallet = 0xe12a94aCBbDd51891ED10dd49e2A556B7678429F;

    address public ProtectiveWallet = 0xfcE22aF32eb862094A17bA5CDe70A34332f4984e; 

     address public USDTRewardWallet = 0xe12a94aCBbDd51891ED10dd49e2A556B7678429F;

     address public PICCRewardWallet = 0x4fd5820BE76d43BdDEf208f79a56D85BDEaDAa83; 

     address public USDTExchangeWallet = 0xd31AffD6406e1f705E0F8f5F2E365bFe288cA629;

     address public PICCServiceChargeWallet = 0xA0aBA006c11474b143aaCc5D944FeAE92C9180A3; 
 
    function setaddress(address addr,uint256 WalletType) public onlyOwner  { 
         if(WalletType == 1){
            ProjectPartyWallet = addr;
        }else if(WalletType == 2){
            RewardWallet = addr;
        }
        else if(WalletType == 3){
            ProtectiveWallet = addr;
        }
        else if(WalletType == 4){
            USDTRewardWallet = addr;
        }
        else if(WalletType == 5){
            PICCRewardWallet = addr;
        }
        else if(WalletType == 6){
            USDTExchangeWallet = addr;
        }
         else if(WalletType == 7){
            PICCServiceChargeWallet = addr;
        }
        


 

    }


    function setPackagelimit( uint256 limit) public only_operator  { 
        PICC_Limit = limit;
        PICCLimitAll = limit;
        PI_Limit = limit;
        CC_Limit = limit;
    }


       function setAllPackagelimit( uint256 limit) public only_operator  { 
           if(PICCLimitAll<limit){
             uint256 ls =   limit.sub(PICCLimitAll);
             PICC_Limit = PICC_Limit.add(ls);
            PI_Limit = PI_Limit.add(ls);
            CC_Limit = CC_Limit.add(ls);

           }else{
                uint256 ls =   PICCLimitAll.sub(limit);
                if(PICC_Limit > ls){
                    PICC_Limit = PICC_Limit.sub(ls);
                }else{
                    PICC_Limit = 0;
 
                }

                 if(PI_Limit > ls){
                    PI_Limit = PI_Limit.sub(ls);
                }else{
                    PI_Limit = 0;
 
                }

                 if(CC_Limit > ls){
                    CC_Limit = CC_Limit.sub(ls);
                }else{
                    CC_Limit = 0;
 
                }
           }


       
    }

    function setPackagePrice(uint256 PackageType,uint256 Price,uint256 share) public only_operator  { 
        PackagePrice[PackageType] = Price;
        Packageshare[PackageType] = share;

        
    }

    function setPlayerPackage(address PCplayerAddress,uint256 PackageType,uint256 PackageQuantity) public only_operator  { 
        PlayerPackage[PCplayerAddress][PackageType] =  PlayerPackage[PCplayerAddress][PackageType].add(PackageQuantity);
    }

     function priceAndBlance() public view returns(uint256,uint256,uint256)   {
       

        uint256 PICCBalance = _PICCIns.balanceOf(address(uniswapV2Pair));
        uint256 USDTBalance = _USDTIns.balanceOf(address(uniswapV2Pair));
        uint256 hBalance = _PICCIns.balanceOf(address(1));
        if(USDTBalance == 0){
            return  (0,0,hBalance);
        }else{
            
            return  (PICCBalance.mul(10000000).div(USDTBalance),PICCBalance,hBalance);
        }
    }
 

 
}