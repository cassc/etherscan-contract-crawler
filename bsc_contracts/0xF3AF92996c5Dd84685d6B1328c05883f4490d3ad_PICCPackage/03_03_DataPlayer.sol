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



   struct Playerinfo{
        bool   CC_Limit; 

        address superiorAddress; 
 
    }


    mapping(address => mapping(uint256 => uint256)) public PlayerPackage; 

        // 套餐价格
    mapping(uint256 => uint256)  public PackagePrice;
    mapping(uint256 => uint256)  public Packageshare;


    // PI_Limit
    mapping(uint256 => uint256)  public PackagePI_Limit;


// CC_Limit
    mapping(uint256 => uint256)  public PackageCC_Limit;


        // 套餐数量上限
    uint256 public PICC_Limit; 
    uint256 public PI_Limit; 
    uint256 public CC_Limit; 

    uint256 public PICCLimitAll; 


 
     mapping(address => Player) public _player; 

       
 
    address public ProjectPartyWallet; 
    address public RewardWallet; 
    address public ProtectiveWallet; 

 
     address public USDTRewardWallet; 
     address public PICCRewardWallet; 

  
 
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


 

    }

// 设置套餐上限
    function setPackagelimit( uint256 limit) public only_operator  { 
        PICC_Limit = limit;
        PICCLimitAll = limit;
        PI_Limit = limit;
        CC_Limit = limit;
    }
// 设置套餐价格
    function setPackagePrice(uint256 PackageType,uint256 Price,uint256 share) public only_operator  { 
        PackagePrice[PackageType] = Price;
        Packageshare[PackageType] = share;

        
    }
// 操作者给用户加套餐
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