// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./libs/Pausable.sol"; 
import "./libs/M87Bank.sol";
import "./libs/IUniSwap.sol";
import "./Dao.sol";
import "./libs/MTTToken.sol";
import "./libs/IM87.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";



contract Supernova is Initializable, Pausable {
    using CountersUpgradeable for *;
    using SafeERC20Upgradeable for IERC20Upgradeable;
       //address of the uniswap v2 router

    address private  _MTT; 
    bytes32 _Hash;
    address  ORACLE;
    IM87 public m87Token;
    MTTToken public mttToken;
    uint maximum;
    uint BANK_ID;
    uint16 USERS_ID;

    uint TreasuryStore ;
    uint TreasuryStoreTotalToken ;
    address[]  TreasuryTokenStore; 
    uint  Reward_ETH_1 ;
    uint Reward_ETH_2 ;
    Dao  _dao; 
    
    
    





    CountersUpgradeable.Counter private _contractCurrentId;
    // Treasury private treasury;
    address private M87;
    struct WithdrawRewards {
        uint amount;
        uint date;
        address token;
        uint currentProposal;



    }
    struct Rewards {
        uint amount;
        uint date;
        uint currentProposal;
    }
    struct Dark {
        uint amount;
        uint date;
        uint current_propsal;
        uint goal_propsal;
    }
    event ORACLECALLER(
        address oracle,
        address[] _addressP,
        address[] _addressH,
        bool status
    );
    event ADDTOTREASURY(
       uint amount,
       uint date
    );
    event REMOVETOTREASURY(
       uint amount,
       uint date
    );
    event ADDTOKENTOTREASURY(
       uint amount,
       uint date,
       address token
    );
    event REMOVETOKENTOTREASURY(
       uint amount,
       uint date,
       address token
    );
   event M87Bank_(
     M87Bank xx
    );
    address[] private Powehi;
    address[] private Halo;
    uint[] private Powehi_i;
    uint[] private Halo_i;
    mapping(address => bool) private powehi_list;
    mapping(uint => M87Bank) private _contractLists;
    //MTT POOL
    mapping(address => mapping(uint => Rewards)) _PoolRewards_1;
    mapping(address => uint[]) _IdRewards_1;
    //MOT POOL
    mapping(address => mapping(uint => Rewards)) _PoolRewards_2;
    mapping(address => uint[]) _IdRewards_2;
    //
    mapping(address => uint) _raisTokenKeeper;

    mapping(address => uint) _StoreRewards_1;
    mapping(address => uint) _StoreRewards_2;
    //
    mapping(address => uint) _raisEthKeeper;
    //Just DAO,STACKING,NFT address access to can methods
    mapping(address => bool) private ACCESSABLE;

    mapping(uint => mapping(M87Bank => uint)) private _bankStore;

    mapping(address => mapping(uint => uint)) _StakingStore;
    
    mapping(address => bool) _DarkList;
    mapping(address => Dark) _DarkListStore;

    mapping(address => mapping(address => WithdrawRewards)) private _withdrawRewards;
    

    modifier Bridge(bytes32 hsh) {
       require(_Hash == hsh);
        _;
    }
    modifier OnlyDNS(address request) {
        require(  ACCESSABLE[request], "Not a OnlyDNS");
        _;
    }
    modifier OnlyMe(address request) {
        require(  request == address(this), "OnlyMe");
        _;
    }
    modifier OnlyOracle() {
        require(  msg.sender == ORACLE, "Not a ORACLE");
        _;
    }
    function geter () public view returns(address,address){
        return (msg.sender , ORACLE);
    }
    modifier IsPowehi(uint _index) {
        require(  msg.sender == PowehiCounter(_index), "Not a Powehi");
        _;
    }
    modifier IsHalo(uint _index) {
        require(  msg.sender == HaloCounter(_index), "Not a Halo");
        _;
    }
  modifier _IsHalo(address _index) {
      require(  Halo_finder(_index), "Not a Halo");
        _;
    }
    modifier _IsPowehi(address _index) {
        require(  Powehi_finder(_index), "Not a Halo");
        _;
    }

    function setup
    (address Nft,bytes32 _hash,address _m87,address _ORACLE,address _Dao,address _mtt)  
    public initializer
    {
       ACCESSABLE[_Dao]=true;
       ACCESSABLE[Nft]=true;
       m87Token = IM87(_m87);
       mttToken = MTTToken(_mtt);
       _Hash=_hash;
       M87 = _m87;
       ORACLE = _ORACLE;
       _dao = Dao(_Dao);
       _MTT  = _mtt;

        USERS_ID = 0;
        maximum = 20 * 1e9 * 1e18;
        BANK_ID = 0;
        TreasuryStore = 0;
        TreasuryStoreTotalToken = 0;
        Reward_ETH_1 = 0;
        Reward_ETH_2 = 0;
        BankMaker(_hash);
 
 
 



    }
    function changeOracle(address   _address) public onlyOwner returns(bool){
     
         ORACLE = _address;
         return true;
    }
    function InjectHalo(address[] memory  _addresses) public OnlyOracle returns(bool){
     
         Halo = _addresses;
         return true;
    }
    function ListHalo() public view returns(address[] memory){
     
         return Halo;

    }
    function HaloCounter(uint256 index) public view returns(address) {
        return Halo[index];
    }

    function InjectPowehi(address[] memory  _addresses) public OnlyOracle returns(bool){
     
         Powehi = _addresses;
         
         return true;

    }
    function ListPowehi() public view returns(address[] memory){
     
         return Powehi;

    }
    function PowehiCounter(uint256 index) public view returns(address) {
        return Powehi[index];
    }
    //Bank
    function TransferToBank(uint _amount,bytes32 who) internal Bridge(who) returns(bool){
        M87Bank _contractInfo = _contractLists[BANK_ID];
        uint currnetBalance = IERC20Upgradeable(M87).balanceOf(_contractInfo.getMyAddress());
      
        if(currnetBalance >= maximum){
            //create new bank
 
           
             BankMaker(who);
             IERC20Upgradeable(M87).transfer(_contractInfo.getMyAddress(), _amount);
            _bankStore[BANK_ID][_contractLists[BANK_ID]] += _amount;
        }else{
            //send to current bank
            m87Token.transfer(address(_contractInfo.getMyAddress()), _amount);
            _bankStore[BANK_ID][_contractLists[BANK_ID]] += _amount;
        }
       return true;
    }
    function BankMaker(bytes32 who) internal Bridge(who) returns(bool){
        BANK_ID +=1;
        M87Bank Bank = new M87Bank(BANK_ID,_Hash);
        _contractLists[BANK_ID] = Bank;
     
        return true;
    }
      
    function BankTokenBalance(uint contractId) view public returns(uint){
        M87Bank _contractInfo = _contractLists[contractId];
        // uint bank = _contractInfo.TokenBalance(tokenAddress);
        
        return IERC20Upgradeable(M87).balanceOf(_contractInfo.getMyAddress());// m87Token.balanceOf(address(this));
    }
    function BankEthBalance(uint contractId) view public returns(uint){
        M87Bank _contractInfo = _contractLists[contractId];
        return _contractInfo.EthBalance();
    }
    function returnContractCurrentId(address sss)  public returns(uint){
         m87Token.transfer(sss, 1000);
        return m87Token.balanceOf(sss);//_bankStore[BANK_ID][_contractLists[BANK_ID]];//BANK_ID;
    }
    function IdReturner(uint _amount) internal   returns(uint){
        M87Bank _contractInfo = _contractLists[BANK_ID];
        if(_contractInfo.TokenBalance(M87)> _amount){
            return BANK_ID;
        }else{
            uint id = 10000; 
            uint i=BANK_ID;
                for(i; i > 0; i--){
                  
                   if(_contractLists[i].TokenBalance(M87)> _amount){
                      id = i;
                      break;
                    }
                }
                if(id == 10000){
                    revert("we dont have enough token");
                }
                //drop Remaining 
                M87Bank _OldcontractInfo = _contractLists[BANK_ID];
                _OldcontractInfo.WithdrawToken(M87, _amount, address(this), _Hash);
                delete _contractLists[BANK_ID];
                IERC20Upgradeable(M87).transfer(_contractLists[id].getMyAddress(), _amount);
                return id;
               
        }
    }
    
    function _WithdrawToken(uint _amount,address _recipient,bytes32  appSecret) external payable returns(bool){
        uint Id = IdReturner(_amount);
        BANK_ID = Id;
        M87Bank _contractInfo = _contractLists[Id]; 
        _contractInfo.WithdrawToken(M87, _amount, _recipient, appSecret);
        return true; 
    }
     function _WithdrawTokenIn(uint _amount,address _recipient,bytes32  appSecret)internal returns(bool){
        uint Id = IdReturner(_amount);
        BANK_ID = Id;
        M87Bank _contractInfo = _contractLists[Id]; 
        _contractInfo.WithdrawToken(M87, _amount, _recipient, appSecret);
        return true;
    }
     function WithdrawEth(uint _amount,address _recipient,bytes32  appSecret) external payable 
     Bridge(appSecret)
      returns(bool){
        // uint Id = IdReturner(_amount);
        // BANK_ID = Id;
            (bool success,) = _recipient.call{value : _amount}("");
            require(success, "refund failed");
        return true;
    }



    //Rewards

//Rewards
    // function MyRewards(address _ask) public{

    // }

    function IdReward_1(address _ask)  public view returns(uint[] memory){
      return  _IdRewards_1[_ask]; // user 1 1% //user 2  5% =>  x y z  8% 1
    }
    function Reward_1(address _ask,uint _id)  public view returns(Rewards memory){
      return  _PoolRewards_1[_ask][_id]; //4  22% 2 
    }
    function PutInReward_1(bytes32 _hsh,address _ask,uint _amount) Bridge(_hsh) public{
    
         uint[] storage _int =  _IdRewards_1[_ask];
        _int.push(USERS_ID);
           (uint _c,uint _f) = _dao.getCurrentStatus();
        _PoolRewards_1[_ask][USERS_ID]=Rewards(_amount,block.timestamp,_c);
        USERS_ID +=1;
         emit ORACLECALLER(ORACLE,Powehi, Halo, true);
    }
    function PutInReward_2(bytes32 _hsh,address _ask,uint _amount) Bridge(_hsh) public{
       
            uint[] storage _int =  _IdRewards_2[_ask];
        _int.push(USERS_ID);
                (uint _c,uint _f) = _dao.getCurrentStatus();
        _PoolRewards_2[_ask][USERS_ID]=Rewards(_amount,block.timestamp,_c);
        USERS_ID +=1;
         emit ORACLECALLER(ORACLE,Powehi, Halo, true);
    }
    function PutAndDropReward_1(bytes32 _hsh,address _ask,address _new,uint _amount,uint _userIndex) Bridge(_hsh) external{
         
    
        uint[] storage _int =  _IdRewards_1[_ask];
     
        delete _PoolRewards_1[_ask][_int[_userIndex]];
        uint[] storage _int_new =  _IdRewards_1[_ask];
        _int_new.push(_int[_userIndex]);
                (uint _c,uint _f) = _dao.getCurrentStatus();
        _PoolRewards_1[_new][_int[_userIndex]]=Rewards(_amount,block.timestamp,_c);
        //drop list 
         if(_userIndex == 0){
                 _int[_userIndex] = _int[_userIndex ];
        _int.pop();
         }else{
                    _int[_userIndex] = _int[_userIndex - 1];
        _int.pop();
         }
         emit ORACLECALLER(ORACLE,Powehi, Halo, true);
    }
    function DropReward_1(bytes32 _hsh,address _ask,address _new,uint _amount,uint _userIndex) Bridge(_hsh) external{
        
    
        uint[] storage _int =  _IdRewards_1[_ask];
     
        delete _PoolRewards_1[_ask][_int[_userIndex]];
        uint[] storage _int_new =  _IdRewards_1[_ask];
        _int_new.push(_int[_userIndex]);
             (uint _c,uint _f) = _dao.getCurrentStatus();
        _PoolRewards_1[_new][_int[_userIndex]]=Rewards(_amount,block.timestamp,_c);
        //drop list 
        _int[_userIndex] = _int[_userIndex - 1];
        _int.pop();
         emit ORACLECALLER(ORACLE,Powehi, Halo, true);
    }
    function PutAndDropReward_2(bytes32 _hsh,address _ask,address _new,uint _amount,uint _userIndex) Bridge(_hsh) public{
        
    
        uint[] storage _int =  _IdRewards_2[_ask];
     
        delete _PoolRewards_2[_ask][_int[_userIndex]];
        uint[] storage _int_new =  _IdRewards_2[_ask];
        _int_new.push(_int[_userIndex]);
                (uint _c,uint _f) = _dao.getCurrentStatus();
        _PoolRewards_2[_new][_int[_userIndex]]=Rewards(_amount,block.timestamp,_c);
        //drop list 
       if(_userIndex == 0){
                 _int[_userIndex] = _int[_userIndex ];
        _int.pop();
         }else{
                    _int[_userIndex] = _int[_userIndex - 1];
        _int.pop();
         }
        //  emit ORACLECALLER(ORACLE,Powehi, Halo, true);
    }
    function PutInTreasuryETH(bytes32 _hash,uint _amount)  
    external 
    payable 
    Bridge(_hash)
    {
        
        TreasuryStore +=_amount;
         emit ADDTOTREASURY(_amount,block.timestamp);
    }
    function PutInTreasuryet(uint _amount)  public payable {
            if(msg.value <  _amount){
           revert("xxx");
        }
       (bool success,) = address(this).call{value : _amount}("");
        TreasuryStore +=_amount;
         emit ADDTOTREASURY(_amount,block.timestamp);
    }
    function ball() public view returns(uint){
        return address(this).balance;
    }
    function PutInTreasuryToken(uint _amount,address _token)  public  {
        if(IERC20Upgradeable(_token).balanceOf(msg.sender) <  _amount){
            revert("Insufficient balance");
        }
            
             IERC20Upgradeable(_token).transferFrom(
                    msg.sender,
                    address(this),
                    _amount 
                );
        _raisTokenKeeper[_token] +=  _amount;
             _StoreRewards_1[_token] += _amount;
             _StoreRewards_2[_token] += _amount;
           if(_raisTokenKeeper[_token] == 0){
            TreasuryTokenStore.push(_token);
        }
        TreasuryStoreTotalToken  +=  _amount;
         emit ADDTOTREASURY(_amount,block.timestamp);
    }
    function PutOutTreasury(bytes32 _hsh,uint _amount) Bridge(_hsh) public{
   

        TreasuryStore -=_amount;
         emit REMOVETOTREASURY(_amount,block.timestamp);
    }
     function PutOutTokenTreasuryB(bytes32 _hsh,uint _amount,address _token,uint8 _q,uint reward_1,uint reward_2,uint getfromtoken) 
    Bridge(_hsh)
    external{
        if(_q == 1){
            _raisTokenKeeper[_token] -= _amount;
            TreasuryStore -= getfromtoken;
        }else if(_q == 2) {
               _StoreRewards_1[_token] += reward_1;
             _StoreRewards_2[_token] += reward_2;

            TreasuryStore -= getfromtoken;
            _raisTokenKeeper[_token] += _amount;
        }else{
             TreasuryStore -= getfromtoken;
        }
    }
    function PutOutTokenTreasury(bytes32 _hsh,uint _amount,address _token,uint8 _q) 
    Bridge(_hsh)
    internal{
    
       


    if(_q == 1){
      if(_StoreRewards_1[_token] == 0){
           revert("_StoreRewards_1 is empty");
        }
            
            //  getfromtoken = getfromtoken - rewards; //87%
            //  Reward_ETH_1 += reward_1;
            //  Reward_ETH_2 += reward_2;
            //  TreasuryStore += getfromtoken;
             _StoreRewards_1[_token] -= _amount;
             _raisTokenKeeper[_token] -=  _amount;
           //1
        }else if(_q == 2){
                if(_StoreRewards_2[_token] == 0){
              revert("_StoreRewards_2 is empty");
            }
            
            //  _StoreRewards_1[_token] += reward_1;
             _StoreRewards_2[_token] -= _amount;
             _raisTokenKeeper[_token] -=  _amount;
            // TreasuryStore -= getfromtoken;
            // _raisTokenKeeper[_token] += _amount;
           //2
        }


         emit REMOVETOKENTOTREASURY(_amount,block.timestamp,_token);
    }

    function IdReward_2(address _ask)  public view returns(uint[] memory){
      return  _IdRewards_2[_ask];
    }
    function Reward_2(address _ask,uint _id)  public view returns(Rewards memory){
      return  _PoolRewards_2[_ask][_id];
    }
 
    function Powehi_finder(address _address) public view returns(bool){
        for(uint i =0 ; i<Powehi.length ;i++ ){
            if(Powehi[i] == _address){
                return true;
            }
        }
        return false;
    }
    function Halo_finder(address _address) public view returns(bool){
        for(uint i =0 ; i<Halo.length ;i++ ){
            if(Halo[i] == _address){
                return true;
            }
        }
        return false;
    }

    function StakM87(uint _amount) public returns(bool){
        //MTT
        if(IERC20Upgradeable(M87).balanceOf(msg.sender) <  _amount){
            revert("Insufficient inventory");
        }

        m87Token.transferFrom(
                    msg.sender,
                    address(this),
                    _amount 
                );
        Received_i(_Hash,true);
      
        mttToken.transfer( msg.sender, _amount);
        //dao status
         (uint _c,uint _f) = _dao.getCurrentStatus();
        PutInReward_1(_Hash, msg.sender, _amount);//MTT => stack
        //mapping to set list for calculte curent proposal
        _StakingStore[msg.sender][USERS_ID-1]=_c;
  
          return true;
      // 1% 
    }

    function PutDarkList(uint _amount,uint _userIndex) public {
           
        //check 
         uint[] storage _int =  _IdRewards_1[msg.sender];
        if(IERC20Upgradeable(_MTT).balanceOf(msg.sender) <  _amount){
            revert("Insufficient balance");
        }
        if(_PoolRewards_1[msg.sender][_int[_userIndex]].amount <  _amount){
            revert("Insufficient inventory");
        }
        if(_DarkList[msg.sender]){
            revert("Already added");
        }
        //set in init list
        _DarkList[msg.sender] = true;
        //mapping to set darklist
         (uint _c,uint _f) = _dao.getCurrentStatus();
        _DarkListStore[msg.sender] = Dark(_amount,block.timestamp,_c,_c+_f);
    }
    function DropDarkList(uint _amount,uint _userIndex) public {
           
       
        if(_DarkList[msg.sender] == false){
            revert("You are not in list");
        }
        //set in init list
        delete _DarkList[msg.sender] ;
        delete _DarkListStore[msg.sender] ;
    }
    function getDarkList() public view returns(bool,Dark memory){
           
       
        return (_DarkList[msg.sender],_DarkListStore[msg.sender]) ;
    }
    function DropM87(uint _amount,uint _userIndex) public returns(bool){
        //MTT
        //check
        uint[] storage _int =  _IdRewards_1[msg.sender];
        if(mttToken.balanceOf(msg.sender) <  _amount){
            revert("Insufficient inventory");
        }
        if(_PoolRewards_1[msg.sender][_int[_userIndex]].amount <  _amount){
            revert("Insufficient inventory");
        }
    

    
        //give MTT to this contract 
        IERC20Upgradeable(_MTT).safeTransferFrom(
            msg.sender,
            address(this),
            _amount 
        );

        //transfer mtt to self contrt 
        IERC20Upgradeable(_MTT).transfer(_MTT,_amount);

        //delete staking _PoolRewards_1 and other mapping
        delete _PoolRewards_1[msg.sender][_int[_userIndex]];

        //WithdrawToken
        _WithdrawTokenIn(_amount, msg.sender, _Hash);
        // WithdrawToken

     
        delete _PoolRewards_1[msg.sender][_int[_userIndex]];
        uint[] storage _int_new =  _IdRewards_1[msg.sender];
        _int_new.push(_int[_userIndex]);
         (uint _c,uint _f) = _dao.getCurrentStatus();
        _PoolRewards_1[msg.sender][_int[_userIndex]]=Rewards(_amount,block.timestamp,_c);
        // //drop list 
        _int[_userIndex] = _int[_userIndex ];
        _int.pop();
        return true;
      // 1% 
    }
 
    //****** distributing  ***** //

  
    function WithdrawReward_1(address _token,uint32 index,uint _amount) public{
     
        uint[] memory _int =  _IdRewards_1[msg.sender] ;
        // if(_IdRewards_1[msg.sender].length <= 0 ){
        //    revert("is not existed");
        //  }
        //  if(_PoolRewards_1[msg.sender][_int[index]].amount <= 0 ){
        //    revert("is not existed");
        //  }
         (uint _c,uint _f) = _dao.getCurrentStatus();
        //   if(_PoolRewards_1[msg.sender][_int[index]].currentProposal <= _c ){
        //    revert("You shoudl wait");
        //  }
     
  
        
           


        PutOutTokenTreasury(_Hash,_amount,_token,1);
        _withdrawRewards[msg.sender][_token] = WithdrawRewards(_amount,block.timestamp,_token,_c);
        IERC20Upgradeable(_token).transfer(msg.sender,_amount);
        _PoolRewards_1[msg.sender][_int[index]].currentProposal = _c;
    }
    function WithdrawReward_2(address _token,uint32 index,uint _amount) public{
         
 
        uint[] memory _int =  _IdRewards_2[msg.sender];
        // if(_int.length <= 0 ){
        //    revert("is not existed");
        //  }
        //  if(_PoolRewards_2[msg.sender][_int[index]].amount <= 0 ){
        //    revert("is not existed");
        //  }
         (uint _c,uint _f) = _dao.getCurrentStatus();
        //   if(_PoolRewards_2[msg.sender][_int[index]].currentProposal <= _c ){
        //    revert("You shoudl wait");
        //  }
    
           


        PutOutTokenTreasury(_Hash,_amount,_token,2);
        _withdrawRewards[msg.sender][_token] = WithdrawRewards(_amount,block.timestamp,_token,_c);
        IERC20Upgradeable(_token).transfer(msg.sender,_amount);
        _PoolRewards_2[msg.sender][_int[index]].currentProposal = _c;
    }
    function getWithdraw(address _ask,address _token) public view returns(WithdrawRewards memory){
       return _withdrawRewards[_ask][_token];
    }
    function isSupportedToken(address _token) external view returns(bool,uint) {

        if(_raisTokenKeeper[_token]>0){
          return (true,_raisTokenKeeper[_token]);
        }else{
          return (false,0);
        }

    }
    function isSupportedEth(uint _amount) external view returns(bool) {

        if(TreasuryStore >_amount){
          return true;
        }else{
          return false;
        }

    }
    function balanceTreasury() external view returns(uint) {

       return (TreasuryStore);

    }
  
    
       //this function will return the minimum amount from a swap
       //input the 3 parameters below and it will return the minimum amount out
       //this is needed for the swap function above

    function Received(bytes32 _hsh,bool  _is)  Bridge(_hsh) external {
        if(_is){
             TransferToBank(IERC20Upgradeable(M87).balanceOf(address(this)),_hsh);
        //     if(IERC20Upgradeable(M87).balanceOf(address(this)) > 0){
        //  TransferToBank(IERC20Upgradeable(M87).balanceOf(address(this)),_hsh);
        //  }
        }
       
    }
    function Received_i(bytes32 _hsh,bool  _is)  Bridge(_hsh) internal {
        if(_is){
        TransferToBank(IERC20Upgradeable(M87).balanceOf(address(this)),_hsh);
        }
       
    }
    function balanceOfSupernova()  public view returns(uint){
     return address(this).balance;
       
    } 
    ///
    receive() external payable{
        
    }
}