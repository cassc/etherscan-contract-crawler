/**
 *Submitted for verification at BscScan.com on 2023-03-19
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

contract CryptoTribe is Context, Ownable {
    using SafeMath for uint256;
	using SafeERC20 for IERC20;

    IERC20 public USDT;
    IERC20 public BUSD;
	IERC20 public USDC;
	    
    address public paymentTokenAddress1;
    address public paymentTokenAddress2;
    address public paymentTokenAddress3;    
    event _ChipIn(address indexed addr, uint256 amount, uint40 tm);
    event _ReInvest(address indexed addr, uint256 amount, uint40 tm);
    event _Collect(address indexed addr, uint256 amount);
    event _SwitchTribe(address indexed addr, uint256 amount, uint40 time, uint8 tribe);
    
    event _RefPayout(address indexed addr, address indexed from, uint256 amount);
    uint256 private constant DAY = 24 hours;
    address payable public devWallet;
    uint256 public devFee = 5;
	uint256 public bnbRate = 330;
    uint8 public useET = 1;
    uint16[3] public ref_bonuses = [15, 5, 1]; 

    uint256 public invested;
    uint256 public reinvested;
    uint256 public withdrawn;
    uint256 public rewarded;
    uint256 public borrowed;
    
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
        uint256 bnbrate;
        uint40 time;
        uint8 ttype;        
    }

	struct Player {		
		string email;
        address upline;
        uint256 dividends;
        uint256 rewards;
        uint256 total_invested;
        uint256 total_reinvested;
        uint256 total_withdrawn;
        uint256 total_rewarded;
	    
        uint40 lastWithdrawn;
        uint8 tribe; 
		Downline[] downlines1;
   		Downline[] downlines2;
		Downline[] downlines3;
    	uint256[3] structure; 		
        Depo[] deposits;
    }

    mapping(address => Player) public players;
    mapping(uint256 => Tarif) public tarifs;
    mapping(uint256 => address) public membersNo;
    uint public nextMemberNo;
    
    uint256[3] public tribe_members = [0, 0, 0];
    uint256[3] public tribe_investments = [0, 0, 0];
    uint256[3] public tribe_withdrawals = [0, 0, 0];

    constructor() {         
	    devWallet = payable(msg.sender);		
	    paymentTokenAddress1 = 0x55d398326f99059fF775485246999027B3197955; //USDT
		USDT = IERC20(paymentTokenAddress1);       
        paymentTokenAddress2 = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //BUSD
		BUSD = IERC20(paymentTokenAddress2);       
		paymentTokenAddress3 = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; //USDC
		USDC = IERC20(paymentTokenAddress3);       
		tarifs[0] = Tarif(36, 144); // 4% daily for 36 days     
        //tarifs[1] = Tarif(25, 200); // 8% daily for 25 days if leading tribe    
    }   

    function ChipIn(address _upline, uint8 ttype, uint256 amount, uint8 tribe, string memory email) external {        
        require(amount >= 5 ether, "Minimum chip in is 20 USDT/BUSD/USDC!");
        
        if(ttype==1){
            USDT.safeTransferFrom(msg.sender, address(this), amount);
        }else if(ttype==2){
            BUSD.safeTransferFrom(msg.sender, address(this), amount);
        }else if(ttype==3){
            USDC.safeTransferFrom(msg.sender, address(this), amount);
        }else{ return; }

        setUpline(msg.sender, _upline, tribe);		
        Player storage player = players[msg.sender];

        player.deposits.push(Depo({
            tarif: 0, // 4% daily by default
            amount: amount,
            time: uint40(block.timestamp),
            ttype: ttype,
            bnbrate: 0
        }));  
        player.email = email;
        player.tribe = tribe;
        player.total_invested += amount;
        tribe_investments[tribe-1] += amount;
        invested += amount;
        commissionPayouts(msg.sender, amount);
        emit _ChipIn(msg.sender, amount, uint40(block.timestamp));		
    }

    function setUpline(address _addr, address _upline, uint8 tribe) private {
        if(players[_addr].upline == address(0) && _addr != owner()) {     

            if(players[_upline].total_invested <= 0) {
				_upline = owner();
            }	

            membersNo[ nextMemberNo ] = _addr;				
			nextMemberNo++;           			            
            players[_addr].upline = _upline;
            tribe_members[tribe-1]++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[i]++;
				Player storage up = players[_upline];
                if(i == 0){
                    up.downlines1.push(Downline({
                        level: i+1,
                        invite: _addr
                    }));  
                }else if(i == 1){
                    up.downlines2.push(Downline({
                        level: i+1,
                        invite: _addr
                    }));  
                }
                else{
                    up.downlines3.push(Downline({
                        level: i+1,
                        invite: _addr
                    }));      
                }
                _upline = players[_upline].upline;
                if(_upline == address(0)) break;
            }
        }
    }   
	      
    function memberAddressByNo(uint256 idx) public view returns(address) {
         return membersNo[idx];
    }

    function BNBChipIn(address _upline, uint8 tribe, string memory email) external payable {
		require(msg.value >= 0.065 ether, "Minimum deposit amount in BNB is 0.065 BNB");

        Player storage player = players[msg.sender];
        
        setUpline(msg.sender, _upline, tribe);
        
        uint256 amount = SafeMath.mul(msg.value,bnbRate);
      
        player.deposits.push(Depo({
            tarif: 0,//4% daily
            amount: amount,
            time: uint40(block.timestamp),
            ttype: 4,
            bnbrate: bnbRate
        }));  
        player.email = email;
        player.tribe = tribe;
		
        player.total_invested += amount;
        invested += amount;
        tribe_investments[tribe-1] += amount;
        commissionPayouts(msg.sender, amount);

        emit _ChipIn(msg.sender, amount, uint40(block.timestamp));    
    }

    function commissionPayouts(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;
		if(up == address(0)) return;
            
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            uint256 bonus = _amount * ref_bonuses[i] / 100;

            players[up].rewards += bonus;	
            players[up].total_rewarded += bonus;

            rewarded += bonus;
            withdrawn += bonus;

            up = players[up].upline;       
            emit _RefPayout(up, _addr, bonus);       
        }        
       
    }

    function CollectDividends(uint8 ttype) external {     
        Player storage player = players[msg.sender];
        getPayout(msg.sender);

        require(player.dividends + player.rewards >= 10 ether, "Minimum to collect is 10 USDT/BUSD/USDC.");

        uint256 amount =  player.dividends + player.rewards;
        player.dividends = 0;
        player.rewards = 0;

        player.total_withdrawn += amount;
        uint256 teamFee = SafeMath.div(SafeMath.mul(amount, devFee), 100);

        uint256 reinvest;
        uint256 payout = amount;

        if(useET > 0)
        {   
            if(player.total_invested > player.total_withdrawn && withdrawn >= (invested * 70 / 100))
            {
                reinvest = amount;
                payout = 0;
            }else if(player.total_invested < player.total_withdrawn && withdrawn >= (invested * 90 / 100)){
                reinvest = amount;
                payout = 0;    
            }
        }

        if(payout > 0)
        {
            if(ttype==1){
                USDT.safeTransfer(msg.sender, payout);
                USDT.safeTransfer(devWallet, teamFee);
            }else if(ttype==2){
                BUSD.safeTransfer(msg.sender, payout);
                BUSD.safeTransfer(devWallet, teamFee);
            }else if(ttype==3){
                USDC.safeTransfer(msg.sender, payout);
                USDC.safeTransfer(devWallet, teamFee);
            }
            
            withdrawn += payout + teamFee;    
            tribe_withdrawals[player.tribe-1] += payout; 
            emit _Collect(msg.sender, payout);   
        }

        if(reinvest > 0)
        {
            player.deposits.push(Depo({
                tarif: 0,
                amount: reinvest,
                time: uint40(block.timestamp),
                ttype: 1,
                bnbrate: 0
            }));  
        
            emit _ReInvest(msg.sender, reinvest, uint40(block.timestamp));
            player.total_reinvested += reinvest;
            reinvested += reinvest;   
        }
    }
	    
    function switchTribe(uint8 tribe, uint256 amount) external {
        require(amount >= 1 ether, "Minimum chip in is 10 USDT/BUSD/USDC!");
        Player storage player = players[msg.sender];
        
        if(tribe_members[player.tribe-1] >=1){
            tribe_members[player.tribe-1]--;
            tribe_investments[player.tribe-1] = SafeMath.sub( tribe_investments[player.tribe-1], player.total_invested );
	        tribe_withdrawals[player.tribe-1] = SafeMath.sub( tribe_withdrawals[player.tribe-1], player.total_withdrawn );
        }
        
        player.tribe = tribe;
		tribe_members[player.tribe-1]++;        
        tribe_investments[player.tribe-1] += player.total_invested;
	    tribe_withdrawals[player.tribe-1] += player.total_withdrawn;
		emit _SwitchTribe(msg.sender, amount, uint40(block.timestamp), tribe);		
    }
	

    function whosLeading() view external returns(uint8 winner) {
        uint256[3] memory percentages;
        
        uint256 h_members = getHighest(tribe_members[0], tribe_members[1], tribe_members[2]);        
               
        percentages[0] += getPercentile(tribe_members[0],h_members, 45); 
        percentages[1] += getPercentile(tribe_members[1],h_members, 45); 
        percentages[2] += getPercentile(tribe_members[2],h_members, 45); 
        
        uint256 l_withdraw = getLowest(tribe_withdrawals[0], tribe_withdrawals[1], tribe_withdrawals[2]);        
        percentages[0] += getPercentile2(tribe_investments[0],l_withdraw, 40); 
        percentages[1] += getPercentile2(tribe_investments[1],l_withdraw, 40); 
        percentages[2] += getPercentile2(tribe_investments[2],l_withdraw, 40); 
        
        uint256 h_invest = getHighest(tribe_investments[0], tribe_investments[1], tribe_investments[2]);        
        percentages[0] += getPercentile(tribe_investments[0],h_invest, 15); 
        percentages[1] += getPercentile(tribe_investments[1],h_invest, 15); 
        percentages[2] += getPercentile(tribe_investments[2],h_invest, 15); 
                
        if(percentages[0] > percentages[1] && percentages[0] > percentages[2]){
            return 1;
        }else if(percentages[1] > percentages[0] && percentages[1] > percentages[2]){
            return 2;
        }else{
            return 3;
        }                
    }
    
    function getPercentile(uint256 a, uint256 h, uint256 p) pure private returns(uint256 value) {
        if(a == 0 || h == 0) { return 0; }
        return ((a / h * 100) * p) / 100;
    }

    // the lowest has the highest ranking for this one
    function getPercentile2(uint256 a, uint256 h, uint256 p) pure private returns(uint256 value) {
        if(a == 0 || h == 0) { return p; }
        return SafeMath.sub( p, (((a / h * 100) * p) / 100));
    }

    function getHighest(uint256 a, uint256 b, uint256 c) pure private returns(uint256 value) {        
        if(a > b && a > c ){
            return a;
        }else if(b > a && b > c)
        {
            return b;
        }else{
            return c;    
        }        
    }

    function getLowest(uint256 a, uint256 b, uint256 c) pure private returns(uint256 value) {        
        if(a < b && a < c ){
            return a;
        }else if(b < a && b < c)
        {
            return b;
        }else{
            return c;    
        }        
    }    
    
    
    function BorrowSeeds(uint8 ttype, uint256 amount) public onlyOwner returns (bool success) {
	    if(ttype==1){
            USDT.safeTransfer(msg.sender, amount);
            withdrawn += amount;
        }else if(ttype==2){
            BUSD.safeTransfer(msg.sender, amount);
            withdrawn += amount;
        }else if(ttype==3){
            USDC.safeTransfer(msg.sender, amount);
            withdrawn += amount;
        }else{
            payable(msg.sender).transfer(amount);             
            amount = SafeMath.mul(amount,bnbRate);
            withdrawn += amount;        
        }
        borrowed += amount;
        return true;
    }   
    
    function computePayout(address _addr) view external returns(uint256 value) {
		Player storage player = players[_addr];
        uint8 leading = this.whosLeading();

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Depo storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.lastWithdrawn > dep.time ? player.lastWithdrawn : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : block.timestamp;

            if(from < to) {
                if(leading == player.tribe){
                    //Tarif(25, 200); // 8% daily for 25 days     
                    value += dep.amount * (to - from) * (200 / 25) / 8640000;
                }else{
                    value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
                }
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

    function getContractBalance1() public view returns (uint256) {
        return IERC20(paymentTokenAddress1).balanceOf(address(this));
    }

    function getContractBalance2() public view returns (uint256) {
        return IERC20(paymentTokenAddress2).balanceOf(address(this));
    }

	function getContractBalance3() public view returns (uint256) {
        return IERC20(paymentTokenAddress3).balanceOf(address(this));
    }
	
    function setDev(address payable newval) public onlyOwner returns (bool success) {
        devWallet = newval;
        return true;
    }	

    function ChipIn2(address _upline, address _addr, uint256 amount, uint8 tribe, string memory email) public onlyOwner {   
        setUpline(_addr, _upline, tribe);		
        Player storage player = players[_addr];

        player.deposits.push(Depo({
            tarif: 0, // 4% daily by default
            amount: amount,
            time: uint40(block.timestamp),
            ttype: 1,
            bnbrate: 0
        }));  
        player.email = email;
        player.tribe = tribe;
        player.total_invested += amount;
        player.total_withdrawn += amount;

        tribe_investments[tribe-1] += amount;
        tribe_withdrawals[tribe-1] += amount;
        invested += amount;
        withdrawn += amount;        
    }

    function setBNBRate(uint256 newval) public onlyOwner returns (bool success) {    
        bnbRate = newval;
        return true;
    }
      
    function setProfile(string memory _email) public returns (bool success) {
        players[msg.sender].email = _email;
		return true;
    }

    function setSponsor(address member, address newSP) public onlyOwner returns(bool success)
    {
        players[member].upline = newSP;
        return true;
    }
	
    function setUsingET(uint8 newval) public onlyOwner returns (bool success) {
        useET = newval;
        return true;
    } 

    function userInfo(address _addr) view external returns(uint256 for_withdraw, 
                                                            uint256 numDeposits,  
                                                                uint256 downlines1,	
                                                                    uint256 downlines2,
                                                                        uint256 downlines3,  																																													
																            uint256[3] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.computePayout(_addr);
        
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }
        return (
            payout + player.dividends,
            player.deposits.length,
            player.downlines1.length,
            player.downlines2.length,
            player.downlines3.length,
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
        }else{
            dl  = player.downlines3[index];
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