pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed
  
import "./Base.sol";
contract DataPlayer is Base {
        using SafeMath for uint256;

 
    uint256 public _NodePlayerCount; 
    uint256 public _SupernodeCount; 
    uint256 public _SEOSPlayerCount; 
 
    uint256 public _IDOCount; 
 
    
    uint256 public _IDOUnlockTime = 1000000000;
    uint256  public IDOtimeLimitS = 1000000000;
    uint256  public IDOtimeLimitE = 1000000000;



  
 

    uint256 public CurrentOutput; //全网当前产出




    mapping(address => uint256) public _SEOSAddrMap; 
    mapping(uint256 => uint256) public everydaytotle; 
    mapping(uint256 => uint256) public everydayDTtotle; 
    mapping(uint256 => uint256) public everydayTotalOutput; 
    uint256  public  allNetworkCalculatingPower; //全网算力
    uint256  public allNetworkCalculatingPowerDT; //全网推广算力



    uint256 public bonusNum; //EOS生态网络基金会加权分红总额   创世节点20%加权分红  超级节点50%加权分红
    uint256 public NFTbonusNum; //NFT分红
    uint256 public NFTcastingTime; //NFT可以铸造的时间

    uint256 public bonusTime; //分红时间
    uint256 public NFTbonusTime; //分红时间
    mapping(uint256 => SEOSPlayer) public  _SEOSPlayerMap;
    // mapping(uint256 => JF) public  JFFH;

    struct SEOSPlayer{
            uint256 id; 
            address addr; 
            uint256 integral; //积分
            address superior;//上级    
            uint256 NFTmintnumber;//NFT可铸造数量

            uint256 SEOSQuantity;//可提现代币
            uint256 teamTotalDeposit;//业绩
            // uint256 communitySEOSQuantity;//社区收益

             uint256 EOSQuantity;//社区收益




            uint256 level;//推 等级
            uint256[]  IDlist;//下级集合
            mining EOSmining;//挖矿相关
            IDO PlayerIDO;//IDO
            GenesisNodePlayer GenesisNode;//创世节点
            SupernodePlayer Supernode;//超级节点

            uint256 USDT_T_Quantity;//推荐奖励  分享奖励
   

     }

 
    struct IDO{
        bool IDO;//IDO只能参与一次
        uint256 IDORecommend;//IDO推荐的数量
        uint256 LockWarehouse;//锁仓数量
    }
  
    // 挖矿
    struct mining{
        uint256 OutGold;//出局金额
        uint256 dynamic;//动态算力  推荐算力
   
        uint256 CalculatingPower;// 累计算力
        uint256 LastSettlementTime;//最后结算时间
    }
//  创世节点
    struct GenesisNodePlayer{
        uint256 id; 
        uint256 investTime; //参与时间
        uint256 LockUp; //锁仓
        uint256 LastReceiveTime;//最后结算时间
        uint256 bonusTime; //分红时间
        uint256 NFTbonusTime; //分红时间
        bool integralturn; //分红时间

    }
 
    struct SupernodePlayer{
        uint256 id; 
        uint256 LockUp; //锁仓
        uint256 LastReceiveTime;//最后结算时间
        uint256 investTime; //参与时间
        uint256 bonusTime; //分红时间
        uint256 NFTbonusTime; //分红时间
    }

 

    mapping(uint256 => detailed) public  detailedMap;

    struct detailed{
        uint256 id; 
        uint256 Dynamic;//动态
        uint256 miningStatic;//挖矿静态
        uint256 shareSEOS;//分享SEOS收益
        uint256 shareEOS;//分享EOS收益
        uint256 AdministrationSEOS;//社区SEOS收益
        uint256 AdministrationEOS;//社区EOS收益
 
    }
 
 
    function set721Address(address value) public   {
        EOSSNFT = ERC721(value);
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

     
    function setStartTime(uint256 _startTimes) public onlyOwner {
        _startTime = _startTimes;
    }
 
 
 
    
    
 
 
// IDO单价
    function getprice() public view  returns(uint256){
            return  _IDOCount.div(2).mul(5000000000000000000).add(100000000000000000000);
    }
 
 

  

// 当前是系统开始的地几天
    function getdayNum(uint256 time) public view returns(uint256) {
        return (time.sub(_startTime)).div(oneDay);
    }
    
    // 获取当日产出
    function getCapacity() public     {


        // CurrentOutput = 10000000000000000000000;

        uint256 USDTq = allNetworkCalculatingPower.div(900000000000000000000000);
        if(USDTq > 0){
            CurrentOutput = CurrentOutput.add(USDTq.mul(30000000000000000000000));
        }else{
            CurrentOutput = 50000000000000000000000;
        }
    }

// 推广算力计算
    function grantProfitsl(address superior,uint256 GbonusNum,uint256 Algebra ) internal   {
        if(Algebra > 0){
            uint256 id = _SEOSAddrMap[superior];
            if(id > 0 ){
                _SEOSPlayerMap[id].EOSmining.dynamic = _SEOSPlayerMap[id].EOSmining.dynamic.add(GbonusNum);
                address sjid =  _SEOSPlayerMap[id].superior;

                grantProfitsl(sjid,  GbonusNum.div(2),  Algebra.sub(1) );
                uint256 Daynumber =  getdayNum(block.timestamp);
                everydayDTtotle[Daynumber] = everydayDTtotle[Daynumber].add(GbonusNum);
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
 

// 分红 
    function setbonusNum(uint256 SbonusNum,uint256 SbonusTime) public  onlyOwner{
        bonusNum = SbonusNum;
        bonusTime = SbonusTime;
    }
 

 

 
    function setIDOTime(uint256 _Time,uint256 IDOType) public onlyOwner {
        if(IDOType == 1){
            _IDOUnlockTime = _Time;
        }
        if(IDOType == 2){
            IDOtimeLimitS = _Time;
        }
        if(IDOType == 3){
            IDOtimeLimitE = _Time;
        }
         if(IDOType == 4){
            NFTcastingTime = _Time;
        }
    }
    function getplayerinfo(address playerAddr) external view returns(SEOSPlayer memory  ){
            uint256 id = _SEOSAddrMap[playerAddr];
            SEOSPlayer memory  player  = _SEOSPlayerMap[id];
        return player;
     }




    //   function getplayerSEOSFH(address playerAddr) external view returns(JF memory  ){
    //         uint256 id = _SEOSAddrMap[playerAddr];
    //         JF memory  player  = JFFH[id];
    //     return player;
    //  }

    function getXJAddress(address playerAddr) public view returns(address[] memory,uint256[] memory     ){
        address[] memory playerinfo = new address[](10);
        uint256[] memory timeinfo = new uint256[](10);
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
        return (playerinfo,timeinfo);
     }

    function getAddressByID(uint256 id) external view returns(address){
        SEOSPlayer memory  player  = _SEOSPlayerMap[id];
        return player.addr;
    }



    function getIDByAddress(address addr) external view returns(uint256){
        uint256 id = _SEOSAddrMap[addr];    
  
  
  
      return id;
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
        // JF memory  JFplayer  = JFFH[id];
 
        uint256[] memory temp = new uint256[](26);

        temp[0] = player.id;
        temp[1] = player.EOSmining.OutGold;
        temp[2] = player.SEOSQuantity;
        temp[3] = player.EOSQuantity;
        temp[4] = player.PlayerIDO.IDORecommend;


        temp[5] = player.GenesisNode.id;


        temp[6] =player.Supernode.id;
        uint256 Tid = _SEOSAddrMap[player.superior];

        temp[7] =Tid;




        // temp[7] =JFplayer.SEOSQuantity;
        // temp[8] =JFplayer.TSEOSQuantity;
        // temp[9] =JFplayer.communitySEOSQuantity;
        // temp[10] =JFplayer.USDT_T_Quantity;

        temp[11] =player.integral;

       
 
  

        return temp; 
        
    }
    




}


