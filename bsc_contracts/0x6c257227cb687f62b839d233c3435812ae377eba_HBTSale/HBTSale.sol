/**
 *Submitted for verification at BscScan.com on 2023-05-09
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

contract HBTSale is Context, Ownable {
    using SafeMath for uint256;
	using SafeERC20 for IERC20;
    
    event _buy(address indexed addr, uint256 amount, uint40 tm);
    event _referral(address indexed addr, address indexed from, uint256 amount);
        
    IERC20[4] public Tether;
    
    address[4] public paymentTokenAddress = [0x55d398326f99059fF775485246999027B3197955, 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56,
                                             0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d, 0xE7D048F2e6c416153029dbC5841FFeCEE71318C4];
    
    address payable public dev1;
    address payable public dev2;
    address payable public dev3;
    
    
    uint256 private constant DAY = 24 hours;
    uint256 public numDays = 60;    
    uint8 public isScheduled = 0;
    
    uint8 public isTransacting = 1;
    uint8 public isVesting = 0; //no vesting
    
    uint256[10] public ref_bonuses = [30, 10, 10, 10, 10, 10, 10, 10, 10, 10]; 
    uint256[7] public rates = [330, 30, 50, 100];
    uint256[2] public token_rates = [667, 500];
    uint256[2] public minimums = [0.05 ether, 50 ether];
    uint16 constant PERCENT_DIVIDER = 1000; 
    uint256 public sold;
    uint256 public rewards;
    uint256 public released;
    uint256 public vested;
    
    struct Downline {
        uint8 level;    
        address invite;
    }

    struct Vesting {
        uint256 life_days;
        uint256 percent;
    }

    struct Depo {
        uint256 tarif;
        uint256 amount;
        uint40 time; 
        uint256 bnbrate;            
    }

	struct Holder {		
		address upline;
        uint256 claimable;
        uint256 total_invested;
        uint256 total_rewards;	    
        uint256 total_received;

        uint40 lastReceived;
        Downline[] downlines1;
   		Downline[] downlines2;
   		Downline[] downlines3;
        Downline[] downlines4;
        Downline[] downlines5;
        Downline[] downlines6;
        Downline[] downlines7;
        Downline[] downlines8;
        Downline[] downlines9;
        Downline[] downlines10;        
   		uint256[10] structure; 		
        Depo[] deposits;        
    }

    mapping(address => Holder) public holders;
    mapping(uint256 => Vesting) public vestings;
    mapping(uint256 => address) public holdersNo;
    uint public nextHolderNo;
    
    constructor() { 
        dev1 = payable(0x11Ee2041b3f231643977F8615dDe032C83407650); 
        dev2 = payable(0x33359Eea87391736124fC175432eDfB53A1b57B6); 
        dev3 = payable(0x241A7ee44148073b0F05B5eDE3FFd4875ea1f1b6); 
        
        Tether[0] = IERC20(paymentTokenAddress[0]);       
        Tether[1] = IERC20(paymentTokenAddress[1]);       
        Tether[2] = IERC20(paymentTokenAddress[2]);       
		Tether[3] = IERC20(paymentTokenAddress[3]);       
    }   

    function BuyHBT(address _upline, uint256 v) external payable {
        
        require(isTransacting > 0,"We're temporarily not on business!");
        require(msg.value >= minimums[0], "Your BNB is less than minimum entry!");
        
        Holder storage holder = holders[msg.sender];
        setUpline(msg.sender, _upline);
        
        uint256 token; 
        token = SafeMath.mul(msg.value, token_rates[0]);
        
        holder.total_invested += msg.value;
        sold += token;
                
        if(isVesting > 0)
        {
            uint amt = SafeMath.div(SafeMath.mul(token, token_rates[1]), PERCENT_DIVIDER);
            token -= amt;
            holder.deposits.push(Depo({
                tarif: v,
                amount: amt,
                time: uint40(block.timestamp),
                bnbrate: 0           
            })); 
            vested += amt;
        }

        holder.total_received += token;
        Tether[3].safeTransfer(msg.sender, token); 
        released += token;       

        commissionPayouts(msg.sender, msg.value);
        
        uint256 m = SafeMath.div(SafeMath.mul(msg.value, rates[1]), PERCENT_DIVIDER);
        payable(dev1).transfer(m);     

        m = SafeMath.div(SafeMath.mul(msg.value, rates[2]), PERCENT_DIVIDER);
        payable(dev2).transfer(m);     
        
        m = SafeMath.div(SafeMath.mul(msg.value, rates[3]), PERCENT_DIVIDER);
        payable(dev3).transfer(m);     
        
        emit _buy(msg.sender, msg.value, uint40(block.timestamp));

    }
    
    function commissionPayouts(address _addr, uint256 _amount) private {
        address up = holders[_addr].upline;
        if(up == address(0) || up == owner()) return;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            payable(up).transfer(bonus);
            
            holders[up].total_rewards += bonus;

            rewards += bonus;
            emit _referral(up, _addr, bonus);
            up = holders[up].upline;
        }       
    }

    function setUpline(address _addr, address _upline) private {
        if(holders[_addr].upline == address(0) && _addr != owner()) {     

            if(holders[_upline].total_invested <= 0) {
				_upline = owner();
            }	
            holdersNo[ nextHolderNo ] = _addr;				
			nextHolderNo++;           			            
            holders[_addr].upline = _upline;
            
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                holders[_upline].structure[i]++;
				Holder storage up = holders[_upline];
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
                }else if(i == 5){
                    up.downlines6.push(Downline({
                        level: 6,
                        invite: _addr
                    }));  
                }else if(i == 6){
                    up.downlines7.push(Downline({
                        level: 7,
                        invite: _addr
                    }));  
                }else if(i == 7){
                    up.downlines8.push(Downline({
                        level: 8,
                        invite: _addr
                    }));  
                }else if(i == 8){
                    up.downlines9.push(Downline({
                        level: 9,
                        invite: _addr
                    }));  
                }else if(i == 9){
                    up.downlines10.push(Downline({
                        level: 10,
                        invite: _addr
                    }));  
                }
                
                _upline = holders[_upline].upline;
                if(_upline == address(0)) break;
            }
        }
    } 

    function endSale(uint256 amount) public onlyOwner returns (bool success) {
	    Tether[3].safeTransfer(msg.sender, amount);
        isTransacting = 0;
        return true;
    }

    function collectSale(uint256 amount) public onlyOwner returns (bool success) {
        payable(msg.sender).transfer(amount);
        return true;
    }

    /*
    function computeVesting(address _addr) view external returns(uint256 value) {
		Holder storage player = holders[_addr];
        
        for(uint256 i = 0; i < player.deposits.length; i++) {
            Depo storage dep = player.deposits[i];
            Vesting storage tarif = vestings[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.lastReceived > dep.time ? player.lastReceived : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : block.timestamp;

            if(from < to) {
                value += dep.amount * (to - from) * (tarifs[0].percent / tarifs[0].life_days) / 8640000;
            }
        }
        return value;
    }

    function getPayout(address _addr) private {
        uint256 payout = this.computeVesting(_addr);
        if(payout > 0) {            
            holders[_addr].lastReceived = uint40(block.timestamp);
            holders[_addr].claimable += payout;
        }
    }      
*/

    function getContractBalance(uint256 index) public view returns (uint256) {
        return IERC20(paymentTokenAddress[index]).balanceOf(address(this));
    }
    
    function setPaymentToken(uint8 index, address newval) public onlyOwner returns (bool success) {
        paymentTokenAddress[index] = newval;
        Tether[index] = IERC20(paymentTokenAddress[index]); 
        return true;
    }

    function setTransacting(uint8 t) public onlyOwner returns (bool success) {    
        isTransacting = t;
        return true;
    }   

    function setVesting(uint8 v) public onlyOwner returns (bool success) {    
        isVesting = v;
        return true;
    }   

    function setRate(uint8 index, uint256 index2, uint256 newval) public onlyOwner returns (bool success) {    
        if(index==1)
        {
            rates[index2] = newval;
        }else if(index==2){
            token_rates[index2] = newval;        
        }else if(index==2){
            ref_bonuses[index2] = newval;
        }else if(index==3){
            minimums[index2] = newval;
        }
        return true;
    }   
       
    function setPercentage(uint256 index, uint256 total_days, uint256 total_perc) public onlyOwner returns (bool success) {
	    vestings[index] = Vesting(total_days, total_perc);
        return true;
    }

    function setScheduled(uint8 sked, uint dayz) public onlyOwner returns (bool success) {
        isScheduled = sked;
        numDays = dayz;
        return true;
    }   

	function setSponsor(address member, address newSP) public onlyOwner returns(bool success)
    {
        holders[member].upline = newSP;
        return true;
    }

    function setWallet(uint8 index, address payable newval) public onlyOwner returns (bool success) {
        if(index==1){
            dev1 = newval;
        }else if(index==2){
            dev2 = newval;
        }else if(index==3){
            dev3 = newval;
        }
        return true;
    }	
	
    function memberAddressByNo(uint256 idx) public view returns(address) {
         return holdersNo[idx];
    }      

    function holdersInfo(address _addr) view external returns(uint256 for_withdraw, 
                                                                uint256 numDeposits,  
                                                                    uint256[10] memory structure) {
        Holder storage player = holders[_addr];
        uint256 payout = 0;//this.computeVesting(_addr);        
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.claimable,
            player.deposits.length,
         	structure
        );
    } 
    
    function memberDownline(address _addr, uint8 level, uint256 index) view external returns(address downline)
    {
        Holder storage player = holders[_addr];
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
        }else if(level == 5)
        {
            dl  = player.downlines5[index];
        }else if(level == 6)
        {
            dl  = player.downlines6[index];
        }else if(level == 7)
        {
            dl  = player.downlines7[index];
        }else if(level == 8)
        {
            dl  = player.downlines8[index];
        }else if(level == 9)
        {
            dl  = player.downlines9[index];
        }
        else{
            dl  = player.downlines10[index];
        }        
        return(dl.invite);
    }

    function memberVestings(address _addr, uint256 index) view external returns(uint40 time, uint256 amount, uint256 lifedays, uint256 percent)
    {
        Holder storage player = holders[_addr];
        Depo storage dep = player.deposits[index];
        Vesting storage tarif = vestings[dep.tarif];
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