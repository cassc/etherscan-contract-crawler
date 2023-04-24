/**
 *Submitted for verification at BscScan.com on 2023-04-24
*/

// SPDX-License-Identifier: MIT License
pragma solidity 0.8.9;
interface IERC20 {    
	function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function getOwner() external view returns (address);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address _owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _owner;
    }
    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

contract DailysFries is Context, Ownable {
    using SafeMath for uint256;
	using SafeERC20 for IERC20;
    
    event _Deposit(address indexed addr, uint256 amount, uint40 tm);
    event _Withdraw(address indexed addr, uint256 amount);
    event _Reinvest(address indexed addr, uint256 amount, uint40 tm);
    event _RefPayout(address indexed addr, address indexed from, uint256 amount);

    IERC20[4] public Tether;
    
    address[4] public paymentTokenAddress = [0x55d398326f99059fF775485246999027B3197955, 
                                             0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d,
                                             0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56, 0xDe0eB96594DACf18cCa7ae8400e60E445d512fAe];
   
    address payable public ceo;
    address payable public dev;
    address payable public mkg1;
    address payable public mkg2;
    address payable public mkg3;
    address payable public mkg4;
    address payable public mkg5;
    address payable public mkg6;
    address payable public mkg7;
    address payable public mkg8;
    
    uint256 private constant DAY = 24 hours;
    uint8 public isScheduled = 1;
    uint256 public numDays = 1;    
    
    uint256[5] public ref_bonuses = [250, 100, 50, 30, 20]; 
    uint256[11] public rates = [320, 50, 25, 25, 25, 25, 25, 25, 25, 25, 1800];
    uint256[3] public minimums = [0.028 ether, 10 ether, 0.01 ether];
   
    uint16 constant PERCENT_DIVIDER = 1000; 
    uint256 public invested;
    uint256 public withdrawn;
    uint256 public rewards;
    uint256 public reinvested;
    uint256 public airdropped;

    struct Downline {
        uint8 level;    
        address invite;
    }

    struct Tarif {
        uint256 life_days;
        uint256 percent;
    }

    struct Depo {
        uint256 tarif;
        uint256 amount;
        uint40 time; 
        uint256 bnbrate;            
    }

	struct Player {		
		address upline;
        uint256 dividends;
        uint256 refbonus;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_reinvested;
        uint256 total_rewards;	    
        uint40 lastWithdrawn;
        Downline[] downlines1;
   		Downline[] downlines2;
   		Downline[] downlines3;
        Downline[] downlines4;
        Downline[] downlines5;
   		uint256[5] structure; 		
        Depo[] deposits;
    }

    mapping(address => Player) public players;
    mapping(uint256 => Tarif) public tarifs;
    mapping(uint256 => address) public membersNo;
    uint public nextMemberNo;
    
    constructor() { 
        ceo = payable(0x1aFf619FD99Db1D485586Aeb4095F3cD554acC94); 
        dev = payable(0x34106D4987BF7aA5fd47Cea395265EA139a22229); 
        mkg1 = payable(0x85ce805f70FBBd64ca3d82bF0D485569752Fe789); 
        mkg2 = payable(0xf27441074D8d7E9a2431e4cF174eA3CAF000543A); 
        mkg3 = payable(0x9B9FBB3bEd2EF3CD62c4c3cCDb1E9587206e4Fd7); 
        mkg4 = payable(0x451fFFE600AD7d4dDE44B6688002509Da91968D2); 
        mkg5 = payable(0x130Dc4F71f53823Ef5F10Bf24b84Ab6D459814fa); 
        mkg6 = payable(0x11d99d73cb8FF2b2c28bdD8D06f7c3251B34348A); 
        mkg7 = payable(0x504f8c87bDEc958e4c6C581d825C6b0D343e9505); 
        mkg8 = payable(0x720eDa4A7f074a8C13E91D97DDBdEE5a13DbC26A); 
        
        Tether[0] = IERC20(paymentTokenAddress[0]);       
        Tether[1] = IERC20(paymentTokenAddress[1]);       
        Tether[2] = IERC20(paymentTokenAddress[2]);       
        Tether[3] = IERC20(paymentTokenAddress[3]);       

        tarifs[0] = Tarif(30, 300); //10% Daily in 30 Days
        tarifs[1] = Tarif(20, 250); //12.5% Daily in 20 Days
        tarifs[2] = Tarif(10, 180); //18% Daily in 10 Days 
        tarifs[3] = Tarif(100, 200); 
        tarifs[4] = Tarif(100, 200); 
    }   

    function BuyFries(address _upline, uint256 taripa) external payable {
        
        require(msg.value >= minimums[0], "Your BNB is less than minimum entry!");
        Player storage player = players[msg.sender];
        setUpline(msg.sender, _upline);
        player.deposits.push(Depo({
            tarif: taripa,
            amount: msg.value,
            time: uint40(block.timestamp),
            bnbrate: 0           
        }));  
        player.total_invested += msg.value;
        invested += msg.value;
        commissionPayouts(msg.sender, msg.value, 4);       
        
        uint256 m = SafeMath.div(SafeMath.mul(msg.value, rates[1]), PERCENT_DIVIDER);
        payable(ceo).transfer(m);      
        withdrawn += m;               
        
        m = SafeMath.div(SafeMath.mul(msg.value, 50), PERCENT_DIVIDER);
        payable(dev).transfer(m);      
        withdrawn += m;               
        
        m = SafeMath.div(SafeMath.mul(msg.value, rates[2]), PERCENT_DIVIDER);
        payable(mkg1).transfer(m);      
        withdrawn += m;               
        
        m = SafeMath.div(SafeMath.mul(msg.value, rates[3]), PERCENT_DIVIDER);
        payable(mkg2).transfer(m);      
        withdrawn += m;               
        
        m = SafeMath.div(SafeMath.mul(msg.value, rates[4]), PERCENT_DIVIDER);
        payable(mkg3).transfer(m);      
        withdrawn += m;               
        
        m = SafeMath.div(SafeMath.mul(msg.value, rates[5]), PERCENT_DIVIDER);
        payable(mkg4).transfer(m);      
        withdrawn += m;  

        uint256 token = SafeMath.mul(msg.value, rates[10]);
        Tether[3].safeTransfer(msg.sender, token);   
        airdropped += token;  

        emit _Deposit(msg.sender, msg.value, uint40(block.timestamp));
    }
    
    function TetherBuyFries(address _upline, uint256 amount, uint8 ttype, uint256 taripa) external { 
       
        require(amount >= minimums[1], "Your stable coin is less than minimum entry!");
        
        if(ttype >= 3) { return; }
        Tether[ttype].safeTransferFrom(msg.sender, address(this), amount);
        
        setUpline(msg.sender, _upline);		
        
        Player storage player = players[msg.sender];
        uint256 bnb = SafeMath.div(amount, rates[0]);
        player.deposits.push(Depo({
            tarif: taripa, 
            amount: bnb,
            time: uint40(block.timestamp),
            bnbrate: rates[0]            
        }));  
        player.total_invested += bnb;
        invested += bnb;
        commissionPayouts(msg.sender, bnb, ttype);
        emit _Deposit(msg.sender, bnb, uint40(block.timestamp));		
        
        uint256 m = SafeMath.div(SafeMath.mul(amount, rates[1]), PERCENT_DIVIDER);   
        Tether[ttype].safeTransfer(ceo, m);         
        withdrawn += m;

        m = SafeMath.div(SafeMath.mul(amount, 50), PERCENT_DIVIDER);   
        Tether[ttype].safeTransfer(dev, m);         
        withdrawn += m;
        
        m = SafeMath.div(SafeMath.mul(amount, rates[2]), PERCENT_DIVIDER);   
        Tether[ttype].safeTransfer(mkg1, m);         
        withdrawn += m;

        m = SafeMath.div(SafeMath.mul(amount, rates[3]), PERCENT_DIVIDER);   
        Tether[ttype].safeTransfer(mkg2, m);         
        withdrawn += m;
        
        m = SafeMath.div(SafeMath.mul(amount, rates[4]), PERCENT_DIVIDER);   
        Tether[ttype].safeTransfer(mkg3, m);         
        withdrawn += m;
        
        m = SafeMath.div(SafeMath.mul(amount, rates[5]), PERCENT_DIVIDER);   
        Tether[ttype].safeTransfer(mkg4, m);         
        withdrawn += m;
                
        amount = SafeMath.div(amount, rates[0]);
        uint256 token = SafeMath.mul(amount, rates[10]);
        Tether[3].safeTransfer(msg.sender, token);   
        airdropped += token;  

        emit _Deposit(msg.sender, amount, uint40(block.timestamp));
    }
    
    function commissionPayouts(address _addr, uint256 _amount, uint8 ttype) private {
        address up = players[_addr].upline;
        if(up == address(0) || up == owner()) return;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
           
            if(ttype <= 3){
                uint256 usd = SafeMath.mul(bonus, rates[0]);    
                Tether[ttype].safeTransfer(up, usd);
            }else {
                payable(up).transfer(bonus);
            }            

            players[up].total_rewards += bonus;

            rewards += bonus;
            emit _RefPayout(up, _addr, bonus);
            up = players[up].upline;
        }       
    }

    function setUpline(address _addr, address _upline) private {
        if(players[_addr].upline == address(0) && _addr != owner()) {     

            if(players[_upline].total_invested <= 0) {
				_upline = owner();
            }	
            membersNo[ nextMemberNo ] = _addr;				
			nextMemberNo++;           			            
            players[_addr].upline = _upline;
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;
				Player storage up = players[_upline];
                if(i == 0){
                    up.downlines1.push(Downline({
                        level: 1,
                        invite: _addr
                    }));  
                }else if(i == 1){
                    up.downlines2.push(Downline({
                        level: 2,
                        invite: _addr
                    }));  
                }else if(i == 2){
                    up.downlines3.push(Downline({
                        level: 3,
                        invite: _addr
                    }));  
                }else if(i == 3){
                    up.downlines4.push(Downline({
                        level: 4,
                        invite: _addr
                    }));  
                }
                else if(i == 4){
                    up.downlines5.push(Downline({
                        level: 5,
                        invite: _addr
                    }));  
                }
                
                _upline = players[_upline].upline;
                if(_upline == address(0)) break;
            }
        }
    } 
       
    function SellFries(uint8 ttype) external  returns (bool success){     
        
        Player storage player = players[msg.sender];
        
        if(isScheduled >= 1) {
            require (block.timestamp >= (player.lastWithdrawn + (DAY * numDays)), "Not due yet for next payout!");
        }
        getPayout(msg.sender);

        require(player.dividends >= minimums[2], "Your dividends is less than minimum payout!");

        uint256 amount =  player.dividends;
        player.dividends = 0;
        
        uint256 usd; uint256 to_reinvest; 
        uint256 payout = amount;
        
        to_reinvest = SafeMath.div(amount,2);
        payout = to_reinvest;        
                  
            usd = SafeMath.mul(payout, rates[0]);                     

            if(ttype <= 2){                     
                Tether[ttype].safeTransfer(msg.sender, usd);

                uint256 m = SafeMath.div(SafeMath.mul(usd, rates[6]), PERCENT_DIVIDER);   
                Tether[ttype].safeTransfer(mkg5, m);         
                withdrawn += m;

                m = SafeMath.div(SafeMath.mul(usd, rates[7]), PERCENT_DIVIDER);   
                Tether[ttype].safeTransfer(mkg6, m);         
                withdrawn += m;
                
                m = SafeMath.div(SafeMath.mul(usd, rates[8]), PERCENT_DIVIDER);   
                Tether[ttype].safeTransfer(mkg7, m);         
                withdrawn += m;
                
                m = SafeMath.div(SafeMath.mul(usd, rates[9]), PERCENT_DIVIDER);   
                Tether[ttype].safeTransfer(mkg8, m);         
                withdrawn += m;
        
            }else {
                payable(msg.sender).transfer(payout);
                
                uint256 m = SafeMath.div(SafeMath.mul(payout, rates[6]), PERCENT_DIVIDER);
                payable(mkg5).transfer(m);      
                withdrawn += m;               
                
                m = SafeMath.div(SafeMath.mul(payout, rates[7]), PERCENT_DIVIDER);
                payable(mkg6).transfer(m);      
                withdrawn += m;               
                
                m = SafeMath.div(SafeMath.mul(payout, rates[8]), PERCENT_DIVIDER);
                payable(mkg7).transfer(m);      
                withdrawn += m;               
                
                m = SafeMath.div(SafeMath.mul(payout, rates[9]), PERCENT_DIVIDER);
                payable(mkg8).transfer(m);      
                withdrawn += m;                          
            }                     
     
       
            player.deposits.push(Depo({
                tarif: 0, 
                amount: to_reinvest,
                time: uint40(block.timestamp),
                bnbrate: 0            
            }));  
            emit _Reinvest(msg.sender, to_reinvest, uint40(block.timestamp));
            player.total_reinvested += to_reinvest;
            reinvested += to_reinvest;


        player.total_withdrawn += amount;
        withdrawn += amount;    
        emit _Withdraw(msg.sender, amount);    
        return true;
    }
	 
    function computePayout(address _addr) view external returns(uint256 value) {
		Player storage player = players[_addr];
    
        for(uint256 i = 0; i < player.deposits.length; i++) {
            Depo storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.lastWithdrawn > dep.time ? player.lastWithdrawn : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : block.timestamp;

            if(from < to) {
                value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }
        return value;
    }

    function getPayout(address _addr) private {
        uint256 payout = this.computePayout(_addr);
        if(payout > 0) {            
            players[_addr].lastWithdrawn = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }      

  
    function getContractBalance(uint256 index) public view returns (uint256) {
        return IERC20(paymentTokenAddress[index]).balanceOf(address(this));
    }
    
    function setPaymentToken(uint8 index, address newval) public onlyOwner returns (bool success) {
        paymentTokenAddress[index] = newval;
        Tether[index] = IERC20(paymentTokenAddress[index]); 
        return true;
    }

    function setRate(uint8 index, uint256 index2, uint256 newval) public onlyOwner returns (bool success) {    
        if(index==1)
        {
            rates[index2] = newval;
        }else if(index==2){
            ref_bonuses[index2] = newval;
        }else if(index==3){
            minimums[index2] = newval;
        }        
        return true;
    }   
       
    function setPercentage(uint256 index, uint256 total_days, uint256 total_perc) public onlyOwner returns (bool success) {
	    tarifs[index] = Tarif(total_days, total_perc);
        return true;
    }

    function setScheduled(uint8 sked, uint dayz) public onlyOwner returns (bool success) {
        isScheduled = sked;
        numDays = dayz;
        return true;
    }   

	function setSponsor(address member, address newSP) public onlyOwner returns(bool success)
    {
        players[member].upline = newSP;
        return true;
    }
    
    
    function setWallet(uint8 index, address payable newval) public onlyOwner returns (bool success) {
        if(index==1){
            ceo = newval;
        }else if(index==2){
            mkg1 = newval;
        }else if(index==3){
            mkg2 = newval;
        }
        else if(index==4){
            mkg3 = newval;
        }
        else if(index==5){
            mkg4 = newval;
        }
        else if(index==6){
            mkg5 = newval;
        }
        else if(index==7){
            mkg6 = newval;
        }
        else if(index==8){
            mkg7 = newval;
        }
        else if(index==9){
            mkg8 = newval;
        }
        return true;
    }	
	
    function memberAddressByNo(uint256 idx) public view returns(address) {
         return membersNo[idx];
    }      

    function userInfo(address _addr) view external returns(uint256 for_withdraw, 
                                                            uint256 numDeposits,  
                                                            uint256[5] memory structure) {
        Player storage player = players[_addr];
        uint256 payout = this.computePayout(_addr);        
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.refbonus,
            player.deposits.length,
         	structure
        );
    } 
    
    function memberDownline(address _addr, uint8 level, uint256 index) view external returns(address downline)
    {
        Player storage player = players[_addr];
        Downline storage dl;
        if(level==1){
            dl  = player.downlines1[index];
        }else if(level == 2)
        {
            dl  = player.downlines2[index];
        }else if(level == 3)
        {
            dl  = player.downlines3[index];
        }else if(level == 4)
        {
            dl  = player.downlines4[index];
        }
        else{
            dl  = player.downlines5[index];
        }
        
        return(dl.invite);
    }

    function memberDeposit(address _addr, uint256 index) view external returns(uint40 time, uint256 amount, uint256 lifedays, uint256 percent)
    {
        Player storage player = players[_addr];
        Depo storage dep = player.deposits[index];
        Tarif storage tarif = tarifs[dep.tarif];
        return(dep.time, dep.amount, tarif.life_days, tarif.percent);
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getOwner() external view returns (address) {
        return owner();
    }
}


library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}