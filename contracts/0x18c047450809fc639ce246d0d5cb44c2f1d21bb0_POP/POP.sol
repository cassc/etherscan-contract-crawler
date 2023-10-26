/**
 *Submitted for verification at Etherscan.io on 2023-10-03
*/

/**
 *Submitted for verification at BscScan.com on 2023-09-09
*/

/**
 *Submitted for verification at Etherscan.io on 2023-09-01
*/

pragma solidity 0.8.7;

interface ITRC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address public _owner;
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {//admin_user
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
       // guanli[newOwner] = 1;
    }



}

contract  POP is  Ownable  {
    mapping (address => address) public inviter;
    uint256 public start_time = 1696089600;
    uint256 public free_profit = 100;
    uint256 public free_day = 100;
    uint256 public free_price = 1000;
    uint256 public free_award = 100;
    uint256 public pledge_profit = 200;//100days  profit   *2
    uint256 public pledge_day = 100;
    uint256 public time_day = 86400;
    
    ITRC20 public  usdt ;
    ITRC20 public  token ;
    
    uint public listCount = 0;
    struct List {
        uint256 types;
        //string zz;
        uint256 amount;
        uint256 status;
        uint256 creatTime;
    }
    mapping  (uint=>List) public lists;
    mapping (uint => address) public listToOwner;
    mapping (uint => address) public listToFrom;
    mapping (uint => uint) public listtype;//1.userfree;2.userpledge;3.takefree;4.takepledge;5.award;
    mapping (address => uint256) public ownerListCount;

    function _savelist(uint256 _types,uint256 _amount,address _user,uint _listtype) internal {
        List  memory list = List(_types,_amount,1,uint32(block.timestamp));
        listCount=listCount+1;
        lists[listCount]=list;
        ownerListCount[_user] = ownerListCount[_user]+1;
        listToOwner[listCount] = _user;
        
        listtype[listCount] = _listtype;
    }
    
    function admin_setfreetime(uint256 _id,uint256 _tt)  external onlyOwner  {
        Listfrees[_id].endTime = _tt;
    }
    
    function admin_setplegtime(uint256 _id,uint256 _tt)  external onlyOwner  {
        Listpledges[_id].endTime = _tt;
    }
    
    uint public freeCount = 0;
    struct Listfree {
        uint256 day;
        uint256 amount;
        uint256 status;
        uint256 creatTime;
        uint256 endTime;
    }
    mapping  (uint=>Listfree) public Listfrees;
    mapping (uint => address) public listfreeToOwner;
    mapping (address => uint256) public ownerListfreeCount;
    function _savefree(uint256 _day ,address _user,uint256 _amount ) internal returns (uint256 backid){
        Listfree  memory listfree = Listfree(_day,_amount/100,1,uint32(block.timestamp),(uint32(block.timestamp)+_day*time_day));
        freeCount=freeCount+1;
        Listfrees[freeCount]=listfree;
        ownerListfreeCount[_user] = ownerListfreeCount[_user]+1;
        listfreeToOwner[freeCount] = _user;
        backid = freeCount;
    }
    
    function checkfree(uint256 _amount) external view returns(uint256 num,uint256 ok){
        num = usdt.balanceOf(msg.sender);
        if(_amount<num){
            ok = 1;
        }
        if(_amount<free_day){
            ok = 0;
        }
        if(_amount>=num){
            ok = 0;
        }
    }
        
    function userfree(address _baba,uint256 _day) public  {
        require(_baba!=msg.sender,"Can't do it yourself");
        require(_day>=free_day,"need more then 100 days");
        require(usdt.balanceOf(msg.sender)>=free_profit*10**16,"const Not enough token");
        uint256 dayss = (uint32(block.timestamp)-start_time)/time_day;
        if (inviter[msg.sender] == address(0)) {
            inviter[msg.sender] = _baba;
        }
        usdt.transferFrom(msg.sender,address(this), free_price*9*10**15);
        uint256 backid = _savefree((_day+dayss),msg.sender,(_day*100/free_day)*free_profit);
        _savelist(1 , free_profit/100,msg.sender,backid);
        usdt.transferFrom(msg.sender,inviter[msg.sender], free_price*free_award*10**13);
        _savelist(5 , free_price*free_award/100000,msg.sender,backid);
    }
      
       
    function takefree(uint256 _id) public  {
        require(listfreeToOwner[_id]==msg.sender,"not yours");
        require(Listfrees[_id].endTime<uint32(block.timestamp),"Not yet in time");
        uint256 dayss = (uint32(block.timestamp)-start_time)/time_day;
        if(dayss>7){
            dayss = 7;
        }
        uint256 money = free_profit*(1-(dayss/7));
        Listfrees[_id].status = 0;
        ownerListfreeCount[msg.sender] = ownerListfreeCount[msg.sender]-1;
        token.transfer(msg.sender, money*10**18);
        _savelist(3 ,money,msg.sender,0);
    }
    
    function oneoffree(uint256 _id) external view returns(uint256 day,uint256 starttime,uint256 endtime,uint256 ok){
        day = Listfrees[_id].day;
        starttime = Listfrees[_id].creatTime;
        endtime = Listfrees[_id].endTime;
        if(uint32(block.timestamp)>endtime){
            ok = 1;
        }else{
            ok = 0;
        }
    }
    
    uint256 public pledgeCount = 0;
    uint256 public pledgesum = 0;
    struct Listpledge {
        uint256 day;
        uint256 amount;
        uint256 amount_end;
        uint256 status;
        uint256 creatTime;
        uint256 endTime;
    }
    mapping  (uint=>Listpledge) public Listpledges;
    mapping (uint => address) public listpledgeToOwner;
    mapping (address => uint256) public ownerListpledgeCount;
    mapping (address => uint256) public ownerpledgesum;
    function _savepledge(uint256 _day ,uint256 _num ,uint256 _num_end ,address _user) internal  returns (uint256 backid){
        Listpledge  memory listpledge = Listpledge(_day,_num,_num_end,1,uint32(block.timestamp),(uint32(block.timestamp)+_day*time_day));
        pledgeCount=pledgeCount+1;
        pledgesum = pledgesum+_num_end;
        Listpledges[pledgeCount]=listpledge;
        ownerListpledgeCount[_user] = ownerListpledgeCount[_user]+1;
        listpledgeToOwner[pledgeCount] = _user;
        ownerpledgesum[_user] = ownerpledgesum[_user]+_num;
        backid = pledgeCount;
    }

    function userpledge(address _baba,uint256 _day,uint256 _num) public  {
        require(_baba!=msg.sender,"Can't do it yourself");
        require(token.balanceOf(msg.sender)>=_num,"Not enough token");
        if (inviter[msg.sender] == address(0)) {
            inviter[msg.sender] = _baba;
        }
        uint256 dayss = (uint32(block.timestamp)-start_time)/time_day;
        uint256 _num_end = (pledge_profit*100/(pledge_day+dayss))*_day*_num;
        //require(token.balanceOf(address(this))>(pledgesum+_num_end/100)*10**18,"const Not enough token");
        token.transferFrom(msg.sender,address(this), _num*10**18);
        uint256 backid = _savepledge(_day,_num,_num_end/10000,msg.sender);
        _savelist(2,_num,msg.sender,backid);
    }
        
    function takepledge(uint256 _id) public  {
        require(listpledgeToOwner[_id]==msg.sender,"not yours");
        require(Listpledges[_id].endTime<uint32(block.timestamp),"Not yet in time");
        token.transfer(msg.sender, Listpledges[_id].amount_end*10**18);
        Listpledges[_id].status = 0;
        ownerListpledgeCount[msg.sender] = ownerListpledgeCount[msg.sender]-1;
        ownerpledgesum[msg.sender] = ownerpledgesum[msg.sender]-Listpledges[_id].amount;
        _savelist(4,Listpledges[_id].amount_end,msg.sender,_id);
    }
    
    function expect_pledge(uint256 _day,uint256 _num) external view returns(uint256 amount){
        uint256 dayss = (uint32(block.timestamp)-start_time)/time_day;
        amount = (pledge_profit/(pledge_day+dayss))*_day*_num;
    }
    
    function oneofpledge(uint256 _id) external view returns(uint256 day,uint256 amount,uint256 amount_end,uint256 starttime,uint256 endtime,uint256 ok){
        day = Listpledges[_id].day;
        amount = Listpledges[_id].amount;
        amount_end = Listpledges[_id].amount_end;
        starttime = Listpledges[_id].creatTime;
        endtime = Listpledges[_id].endTime;
        if(uint32(block.timestamp)>endtime){
            ok = 1;
        }else{
            ok = 0;
        }
    }

    
    function usdtandtoken() external view returns(ITRC20 _usdt,ITRC20 _token){
        _usdt = usdt;
        _token = token;
    }

    
    function user_balance(address _user) external view returns(uint256 num_free,uint256 num_pledge,uint256 sum_pledge){
        num_free = ownerListfreeCount[_user];
        num_pledge = ownerListpledgeCount[_user];
        sum_pledge = ownerpledgesum[_user];
    }
    
    function adminsetusdtaddress(ITRC20 addressusdt,ITRC20 addresstoken)  external onlyOwner  {
        usdt = addressusdt;
        token = addresstoken;
    }
//freeCount pledgeCount pledgesum
    
    function  admin_setcount( uint256 _freeCount,uint256 _pledgeCount,uint256 _pledgesum)  external onlyOwner {
        freeCount = _freeCount;
        pledgeCount = _pledgeCount;
        pledgesum = _pledgesum;
    }    

    function  admin_tixian(address toaddress)  external onlyOwner {
        uint256 qian = usdt.balanceOf(address(this));
        usdt.transfer(toaddress, qian);
    }    
    

    function  admin_set_free(uint256 _free_profit,uint256 _free_day,uint256 _free_price,uint256 _free_award)  external onlyOwner {
        free_profit = _free_profit;
        free_day = _free_day;
        free_price = _free_price;
        free_award = _free_award;
    }    
    
    function  admin_set_starttime(uint256 _start_time )  external onlyOwner {
        start_time = _start_time;
    }

    function  admin_set_pledge(uint256 _pledge_profit,uint256 _pledge_day)  external onlyOwner {
        pledge_profit = _pledge_profit;
        pledge_day = _pledge_day;
    }  
    
    function  admin_set_time_day(uint256 _time_day)  external onlyOwner {
        time_day = _time_day;
    }  
    
    


    constructor( ) {
        _owner = msg.sender;
        //guanli[_owner] = 1;
        start_time = uint32(block.timestamp);
    }




}