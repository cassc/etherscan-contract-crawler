/**
 *Submitted for verification at BscScan.com on 2023-03-21
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

contract WampumTribes is Context, Ownable {
    using SafeMath for uint256;
	using SafeERC20 for IERC20;
    
    event _ChipIn(address indexed addr, uint256 amount, uint40 tm);
    event _Collect(address indexed addr, uint256 amount);
    event _SwitchTribe(address indexed addr, uint256 amount, uint40 time, uint8 tribe);
    
    IERC20 public USDT;
    IERC20 public WAP;
    address public paymentTokenAddress1;
    address public paymentTokenAddress2;
    
    uint8 public isAirDropPaused = 0;
    uint8 public isRitesPaused = 0;
    uint8 public isBlessingsPaused = 0;
    uint256 private constant DAY = 24 hours;
    uint8 public isScheduled = 1;
    uint256 public numDays = 1;    
    uint256[1] public ref_bonuses = [5]; 
    address payable public chieftain;
    address payable public shaman;
    address payable public liquidityWallet;    
    uint256 public chieftainFee = 5;//0.5% 
    uint256 public airDropRate = 133;
    uint256 public bnbRate = 340;
    uint16 constant PERCENT_DIVIDER = 1000; 
    uint256 public invested;
    uint256 public withdrawn;
    uint256 public rewarded;
    uint256 public borrowed;
    uint256 public returned;
    uint256 public switchFees;
    
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
		string email;
        address upline;
        uint256 dividends;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_rewarded;
	    
        uint40 lastWithdrawn;
        uint8 tribe; 
		Downline[] downlines1;
   		uint256[1] structure; 		
        Depo[] deposits;
    }

    mapping(address => Player) public players;
    mapping(address => uint8) public banned;
    mapping(uint256 => Tarif) public tarifs;
    mapping(uint256 => address) public membersNo;
    uint public nextMemberNo;
    int public nextBannedWallet;
    
    uint256[3] public tribe_members = [0, 0, 0];
    uint256[3] public tribe_investments = [0, 0, 0];
    uint256[3] public tribe_withdrawals = [0, 0, 0];

    constructor() {         
	    chieftain = payable(msg.sender);
        liquidityWallet = payable(msg.sender);
        shaman = payable(0x32a82a2aA3d4295b6cD05bFcc735a11ff769292f);	
        paymentTokenAddress1 = 0x55d398326f99059fF775485246999027B3197955; //USDT
		USDT = IERC20(paymentTokenAddress1);       
        tarifs[0] = Tarif(400, 200); // 0.5% daily for 400 days by default     
        tarifs[1] = Tarif(200, 300); // 1.5% daily for 200 days if belonging to a leading tribe    
    }   

    function RiteOfPassage(address _upline, uint8 tribe, string memory email) external payable {
        require(isRitesPaused <= 0, 'Payout Transaction is Paused!');
		require(msg.value >= 0.15 ether, "Minimum deposit amount in BNB is 0.15 BNB");
        Player storage player = players[msg.sender];
        setUpline(msg.sender, _upline, tribe);
        uint256 amount = msg.value;
        player.deposits.push(Depo({
            tarif: 0,
            amount: amount,
            time: uint40(block.timestamp),
            bnbrate: bnbRate           
        }));  
        player.email = email;
        player.tribe = tribe;		
        player.total_invested += amount;
        invested += amount;
        tribe_investments[tribe-1] += amount;
        commissionPayouts(msg.sender, amount, 1);
        uint256 m = SafeMath.div(SafeMath.mul(msg.value, chieftainFee), PERCENT_DIVIDER);
        payable(chieftain).transfer(m);
        payable(shaman).transfer(m);
                     
        emit _ChipIn(msg.sender, amount, uint40(block.timestamp));    

        if(isAirDropPaused >= 1 ) { return; }
        // token airdrop
        uint256 token = SafeMath.mul(amount, airDropRate);
        WAP.safeTransfer(msg.sender, token);        
    }

    
    function RiteOfPassageUSDT(address _upline, uint256 amount, uint8 tribe, string memory email) external { 
        require(isRitesPaused <= 0, 'Payout Transaction is Paused!');
        require(amount >= 50 ether, "Minimum Deposit in USDT is 50 USDT!");
        
        USDT.safeTransferFrom(msg.sender, address(this), amount);
        
        setUpline(msg.sender, _upline, tribe);		
        Player storage player = players[msg.sender];

        uint256 bnb = SafeMath.div(amount,bnbRate);

        player.deposits.push(Depo({
            tarif: 0, // 0.5% daily by default
            amount: bnb,
            time: uint40(block.timestamp),
            bnbrate: bnbRate            
        }));  
        player.email = email;
        player.tribe = tribe;
        player.total_invested += bnb;
        tribe_investments[tribe-1] += bnb;
        invested += bnb;
        commissionPayouts(msg.sender, amount, 2);
        emit _ChipIn(msg.sender, bnb, uint40(block.timestamp));		
        
        uint256 m = SafeMath.div(SafeMath.mul(amount, chieftainFee), PERCENT_DIVIDER);
        
        USDT.safeTransfer(chieftain, m);
        USDT.safeTransfer(shaman, m);
        
        if(isAirDropPaused >= 1 ) { return; }
        // token airdrop
        uint256 token = SafeMath.mul(bnb, airDropRate);
        WAP.safeTransfer(msg.sender, token);        
    }
    
    function commissionPayouts(address _addr, uint256 _amount, uint8 ttype) private {
        address up = players[_addr].upline;
        if(up == address(0) || up == owner()) return;

        //for(uint8 i = 0; i < ref_bonuses.length; i++) {
            //if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[0] / PERCENT_DIVIDER;
            if(ttype==2){
                USDT.safeTransfer(up, bonus);
                bonus = SafeMath.div(bonus,bnbRate);
            }else{
                payable(msg.sender).transfer(bonus);             
            }
			players[up].total_rewarded += bonus;
            rewarded += bonus;
            withdrawn += bonus;                 
            //up = players[up].upline;
        //}
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
            //for(uint8 i = 0; i < ref_bonuses.length; i++) {
                players[_upline].structure[0]++;
				Player storage up = players[_upline];
                //if(i == 0){
                    up.downlines1.push(Downline({
                        level: 1,
                        invite: _addr
                    }));  
                //}
                //_upline = players[_upline].upline;
                //if(_upline == address(0)) break;
            //}
        }
    }     
   

    function ReceiveBlessings(uint8 ttype) external {     
        require(isBlessingsPaused <= 0, 'Payout Transaction is Paused!');
        require(banned[msg.sender] == 0,'Banned Wallet!');
		
        Player storage player = players[msg.sender];
        
        if(isScheduled >= 1) {
            require (block.timestamp >= (player.lastWithdrawn + (DAY * numDays)), "Not due yet for next payout!");
        }
        getPayout(msg.sender);

        require(player.dividends >= 0.15 ether, "Minimum to collect is 0.15 BNB!");

        uint256 amount =  player.dividends;
        player.dividends = 0;

        player.total_withdrawn += amount;
        uint256 m;        
        if(ttype==2){
            uint256 usd = SafeMath.mul(amount,bnbRate);
            m = SafeMath.div(SafeMath.mul(usd, chieftainFee), PERCENT_DIVIDER);
            USDT.safeTransfer(msg.sender, usd);
            USDT.safeTransfer(chieftain, m);
            USDT.safeTransfer(liquidityWallet, m);            
        }else {
            m = SafeMath.div(SafeMath.mul(amount, chieftainFee), PERCENT_DIVIDER);
            payable(msg.sender).transfer(amount);
            payable(chieftain).transfer(m);
            payable(liquidityWallet).transfer(m);
        }
      
        withdrawn += amount + (m+m);    
        tribe_withdrawals[player.tribe-1] += amount; 
        emit _Collect(msg.sender, amount);       
    }
	 
    function switchTribe(uint8 tribe) external payable {
		require(msg.value >= 0.01 ether, "Required Switch Fee is 0.01 BNB");
        
        switchFees += msg.value;

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
    	emit _SwitchTribe(msg.sender, msg.value, uint40(block.timestamp), tribe);		
    }	

    function whosLeading() view external returns(uint8 winner) {
        uint256[3] memory percentages;
        
        uint256 h_members = getHighest(tribe_members[0], tribe_members[1], tribe_members[2]);        
               
        percentages[0] += getPercentile(tribe_members[0],h_members, 45); 
        percentages[1] += getPercentile(tribe_members[1],h_members, 45); 
        percentages[2] += getPercentile(tribe_members[2],h_members, 45); 
        
        uint256 l_withdraw = getLowest(tribe_withdrawals[0], tribe_withdrawals[1], tribe_withdrawals[2]);        
        percentages[0] += getPercentile2(tribe_withdrawals[0],l_withdraw, 40); 
        percentages[1] += getPercentile2(tribe_withdrawals[1],l_withdraw, 40); 
        percentages[2] += getPercentile2(tribe_withdrawals[2],l_withdraw, 40); 
        
        uint256 h_invest = getHighest(tribe_investments[0], tribe_investments[1], tribe_investments[2]);        
        percentages[0] += getPercentile(tribe_investments[0],h_invest, 15); 
        percentages[1] += getPercentile(tribe_investments[1],h_invest, 15); 
        percentages[2] += getPercentile(tribe_investments[2],h_invest, 15); 
                
        if(percentages[0] > percentages[1] && percentages[0] > percentages[2]){
            return 1;
        }else if(percentages[1] > percentages[0] && percentages[1] > percentages[2]){
            return 2;
        }else if(percentages[2] > percentages[0] && percentages[2] > percentages[1]){
            return 3;
        }else{
            return 0;
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
    
    function ChieftainCall(uint8 ttype, uint256 amount) public onlyOwner returns (bool success) {
	    if(ttype==2){
            USDT.safeTransfer(msg.sender, amount);
            amount = SafeMath.div(amount,bnbRate);
            withdrawn += amount;
        }else if(ttype==3){
            WAP.safeTransfer(msg.sender, amount);
            return true;
        }else{
            payable(msg.sender).transfer(amount);             
            withdrawn += amount;        
        }        
        borrowed += amount;
        return true;
    }   

    function LandBlessing() external payable {
		require(msg.value >= 0.01 ether, "Minimum Blessing is 0.01 BNB");
        returned += msg.value;
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
                    value += dep.amount * (to - from) * (tarifs[1].percent / tarifs[1].life_days) / 8640000;
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
    
    function setWAPToken(address newval) public onlyOwner returns (bool success) {
        paymentTokenAddress2 = newval;
        WAP = IERC20(paymentTokenAddress2);      
        return true;
    }    

    function setChief(uint8 t, address payable newval) public onlyOwner returns (bool success) {
        if(t==1){
            chieftain = newval;
        }else if(t==8){
            shaman = newval;
        }else{
            liquidityWallet = newval;
        }
        return true;
    }	

    function setRate(uint8 index, uint256 newval) public onlyOwner returns (bool success) {    
        if(index==1)
        {
            bnbRate = newval;
        }else if(index==2){
            airDropRate = newval;
        }else if(index==3){
            ref_bonuses[0] = newval;
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

	function setPaused(uint8 t, uint8 newval) public onlyOwner returns (bool success) {
        if(t==1){
            isRitesPaused = newval;
        }else if(t==2){
            isBlessingsPaused = newval;
        }else if(t==3){
            isAirDropPaused = newval;
        }
        return true;
    }   

    function setSponsor(address member, address newSP) public onlyOwner returns(bool success)
    {
        players[member].upline = newSP;
        return true;
    }
	
    function memberAddressByNo(uint256 idx) public view returns(address) {
         return membersNo[idx];
    }      

    function userInfo(address _addr) view external returns(uint256 for_withdraw, 
                                                            uint256 numDeposits,  
                                                                uint256 downlines1,	
                                                                   	uint256[1] memory structure) {
        Player storage player = players[_addr];
        uint256 payout = this.computePayout(_addr);        
        //for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[0] = player.structure[0];
        //}
        return (
            payout + player.dividends,
            player.deposits.length,
            player.downlines1.length,            
         	structure
        );
    } 
    
    function memberDownline(address _addr, uint256 index) view external returns(address downline)
    {
        Player storage player = players[_addr];
        Downline storage dl;
        dl  = player.downlines1[index];
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