pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed
  
import "./Base.sol";
contract DataPlayer is Base {
        using SafeMath for uint256;

 
    uint256 public _NodePlayerCount; 
    uint256 public _SupernodeCount; 
    uint256 public _SEOSPlayerCount; 
 
     uint256 public _SupernodeCountbonus; 
    uint256 public _NodePlayerCountbonus; 

    
  
    uint256 public CurrentOutput;  

    mapping(address => uint256) public _SEOSAddrMap; 
    mapping(uint256 => uint256) public everydaytotle; 
    mapping(uint256 => uint256) public everydayDTtotle; 
    mapping(uint256 => uint256) public everydayTotalOutput; 
    uint256  public  allNetworkCalculatingPower; 
    uint256  public allNetworkCalculatingPowerDT;  



    uint256 public bonusNum;  
    uint256 public NFTbonusNum; 
    uint256 public NFTcastingTime; 

    uint256 public bonusTime;  
    uint256 public NFTbonusTime; 
    mapping(uint256 => SEOSPlayer) public  _SEOSPlayerMap;
 


    struct SEOSPlayer{
            uint256 id; 
            address addr; 
            uint256 integral; 
            address superior; 
            uint256 NFTmintnumber; 
            uint256 SEOSQuantity; 
            uint256 teamTotalDeposit; 
            uint256 EOSQuantity; 
            uint256 level; 
            uint256[]  IDlist; 
            mining EOSmining; 
             GenesisNodePlayer GenesisNode; 
            SupernodePlayer Supernode; 
            uint256 USDT_T_Quantity; 
     }

 
    struct mining{
        uint256 OutGold; 
        uint256 dynamic;    
   
        uint256 CalculatingPower; 
        uint256 LastSettlementTime; 
        bool NFTactivation; 

    }
 
    struct GenesisNodePlayer{
        uint256 id; 
        uint256 investTime;  
        uint256 LockUp;  
        uint256 LockUpALL;  
        uint256 LastReceiveTime; 
        uint256 bonusTime; 
        uint256 NFTbonusTime; 
        bool integralturn; 

    }
 
    struct SupernodePlayer{
        uint256 id; 
        uint256 LockUp;
        uint256 LockUpALL;  

        uint256 LastReceiveTime; 
        uint256 investTime; 
        uint256 bonusTime; 
        uint256 NFTbonusTime; 
    }

    uint256 NFTID = 0;

    uint256 public ESOSpriceLS = 333333333;

    mapping(uint256 => detailed) public  detailedMap;

    struct detailed{
        uint256 id; 
        uint256 Dynamic; 
        uint256 miningStatic; 
        uint256 shareSEOS; 
        uint256 shareEOS; 
        uint256 AdministrationSEOS; 
        uint256 AdministrationEOS;
 
        uint256 recommendlevel; 
 
    }
   
    function set721Address(address value) public onlyOwner    {
        EOSSNFT = ERC721(value);
    }

    function SETESOSpriceLS(uint256 amount) public only_Powner only_openOW {
        ESOSpriceLS = amount;
    }

    function ERC20_Convert(uint256 value) internal pure returns(uint256) {
            return value.mul(1000000000000000000);
    }
 


    modifier isNodePlayer() {
        uint256 id = _SEOSAddrMap[msg.sender];
        uint256 Nodeid = _SEOSPlayerMap[id].GenesisNode.id;
        require(Nodeid > 0, "Node"); 
        _; 
    }
    modifier isSuperNodePlayer() {
        uint256 id = _SEOSAddrMap[msg.sender];
       uint256  Supernodeid =   _SEOSPlayerMap[id].Supernode.id;
        require(Supernodeid > 0, "SuperNode"); 
        _; 
    }

    modifier isPlayer() {
        uint256 id = _SEOSAddrMap[msg.sender];
        require(id > 0, "userDoesNotExist"); 
        _; 
    }

   
    function getdayNum(uint256 time) public view returns(uint256) {
        return (time.sub(_startTime)).div(oneDay);
    }
    
 
    function getCapacity() public     {
      uint256 USDTq = allNetworkCalculatingPower.div(1500000000000000000000000);
        if(USDTq > 0){
            CurrentOutput = CurrentOutput.add(USDTq.mul(30000000000000000000000));
        }else{
            CurrentOutput = 50000000000000000000000;
        }
    }

 
    function grantProfitsl(address superior,uint256 GbonusNum,uint256 Algebra ) internal   {
        if(Algebra > 0){
            uint256 id = _SEOSAddrMap[superior];
            if(id > 0     ){
 
                _SEOSPlayerMap[id].EOSmining.dynamic = _SEOSPlayerMap[id].EOSmining.dynamic.add(GbonusNum);
                address sjid =  _SEOSPlayerMap[id].superior;
                allNetworkCalculatingPowerDT = allNetworkCalculatingPowerDT.add(GbonusNum);

                grantProfitsl(sjid,  GbonusNum.div(2),  Algebra.sub(1) );
           
            }
        }
    }


    function addteamTotalDeposit(address superior,uint256 GbonusNum,uint256 Algebra ) internal   {
        if(Algebra > 0){
            uint256 id = _SEOSAddrMap[superior];
            if(id > 0 ){
                _SEOSPlayerMap[id].teamTotalDeposit = _SEOSPlayerMap[id].teamTotalDeposit.add(GbonusNum);
                address sjid =  _SEOSPlayerMap[id].superior;
                addteamTotalDeposit(sjid,  GbonusNum,  Algebra.sub(1) );
           
            }
        }
    }
 

 
    function setbonusNum(uint256 SbonusNum) public only_openOW only_Powner{
        bonusNum = SbonusNum;
        require(block.timestamp.sub(bonusTime) >= 604800, "604800");

        bonusTime = block.timestamp;
        _SupernodeCountbonus = _SupernodeCount;
        _NodePlayerCountbonus = _NodePlayerCount;
    }
 

 

 
    function setTime(uint256 _Time,uint256 IDOType) public onlyOwner {
    
         if(IDOType == 4){
            NFTcastingTime = _Time;
        }
    }
    function getplayerinfo(address playerAddr) external view returns(SEOSPlayer memory  ){
            uint256 id = _SEOSAddrMap[playerAddr];
            SEOSPlayer memory  player  = _SEOSPlayerMap[id];
        return player;
     }

 

    function getXJAddress(address playerAddr) public view returns(address[] memory   ){
        address[] memory playerinfo = new address[](10);
         uint256 id = _SEOSAddrMap[playerAddr];
        SEOSPlayer memory  player  = _SEOSPlayerMap[id];
        uint256[] memory addressID = player.IDlist;
        uint256 length = addressID.length;
        if(length >10)
        {
            length = 10;
        }
        if(length >0)
        {
            for (uint256 m = 0; m < length; m++) {
                playerinfo[m] = this.getAddressByID(addressID[m]);
            }
        }
        return (playerinfo );
     }

    function getAddressByID(uint256 id) external view returns(address){
        SEOSPlayer memory  player  = _SEOSPlayerMap[id];
        return player.addr;
    }

    function getIDtoTotal(address addr) external view returns(uint256){
        uint256 id = _SEOSAddrMap[addr];    
        SEOSPlayer memory  player  = _SEOSPlayerMap[id];
        return player.teamTotalDeposit;
    }

    function getIDByAddress(address addr) external view returns(uint256){
        uint256 id = _SEOSAddrMap[addr];    
      return id;
    }

   function getUsdtToSeos(uint256 amount) public  view returns (uint256 SEOSamount)  {
 
        uint256 SEOSprice = Spire_Price(_SEOSAddr, _SEOSLPAddr);
          
        if(SEOSprice == 0){
            SEOSamount = amount.div(ESOSpriceLS).mul(10000000);
        }else{
            SEOSamount = amount.mul(SEOSprice).div(10000000);
        }
    }
    function getPlayerIncomeDetails(address playerAddr)   external
        view returns(detailed memory s){
        uint256 id = _SEOSAddrMap[playerAddr];
        detailed memory  player  = detailedMap[id];
        return player;
    }

   function getPlayerByAddress(address playerAddr) public view returns(uint256[] memory) { 

 
 
        uint256 id = _SEOSAddrMap[playerAddr];

        SEOSPlayer memory  player  = _SEOSPlayerMap[id];
 
 
        uint256[] memory temp = new uint256[](26);

        temp[0] = player.id;
        temp[1] = player.EOSmining.OutGold;
        temp[2] = player.SEOSQuantity;
        temp[3] = player.EOSQuantity;
        temp[4] = 0;


        temp[5] = player.GenesisNode.id;


        temp[6] =player.Supernode.id;
        uint256 Tid = _SEOSAddrMap[player.superior];

        temp[7] =Tid;
 
        temp[11] =player.integral;

       
 
  

        return temp; 
        
    }
    




}


