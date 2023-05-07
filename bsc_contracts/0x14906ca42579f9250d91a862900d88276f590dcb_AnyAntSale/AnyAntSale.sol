/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

/* SPDX-License-Identifier: SimPL-2.0*/
pragma solidity >=0.6.2;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) external; }

contract Owner {
    address private owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor()  {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }
   
}	
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }	

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
library DateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    function _daysToDate(uint _days) internal pure returns(uint year, uint month, uint day) {
        int __days = int(_days);

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
		(year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
		
		day_str=year*100*100+month*100+day;
    }

}
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint);
    function balanceOf(address owner) external view returns(uint);
    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint value) external returns(bool);
    function transfer(address to, uint value) external returns(bool);
    function transferFrom(address from, address to, uint value) external returns(bool);
} 
 
contract AnyAntSale is Owner {
	 
    using SafeMath
    for uint;
    
	uint public index=0;
	uint pre=9500;
	
	
	address to_address;
	 
	
	mapping(address => uint256) public address_index;
	mapping(uint256 => address) public index_address;
	mapping(uint256 => address) public coin_addr_lists;
	mapping(uint256 => uint256) public amount_lists;
	mapping(uint256 => address) public sell_address_lists;
	mapping(uint256 => address) public buy_address_lists;
	
	 
	
	mapping(uint256 => uint256) public buy_start_time_lists;
	mapping(uint256 => uint256) public buy_end_time_lists;
	mapping(uint256 => uint256) public buy_min_amount_lists;
	mapping(uint256 => uint256) public buy_max_amount_lists;
	mapping(uint256 => uint256) public price_type_lists;
	mapping(uint256 => uint256) public release_type_lists;
	mapping(uint256 => uint256) public price_length_lists;
	mapping(uint256 => uint256) public release_length_lists;
	mapping(uint256 => uint256) public left_amount_lists;
	mapping(uint256 => uint256) public price_start_lists;
	mapping(uint256 => uint256) public price_end_lists;
	mapping(uint256 => uint256) public release_daypre_lists;
	mapping(uint256 => uint256) public release_starttype_lists;
	mapping(uint256 => uint256) public release_timetype_lists;
    mapping(uint256 => uint256) public release_daytime_lists;
    mapping(uint256 => uint256) public is_buy_type_lists;

  
	mapping(uint256 => uint256) public sell_amount_lists;
	mapping(uint256 => uint256) public buy_amount_lists;
	 
     

	mapping(address => mapping(address => uint256)) public admin_amount_lists;
    mapping(uint256 => mapping(address => uint256)) public buy_time_lists;
    
    mapping(uint256 => mapping(address => uint256)) public user_getamount_lists;
	mapping(uint256 => mapping(uint256 => uint256)) public price_amount_lists;
	mapping(address => mapping(uint256 => uint256)) public user_amount_lists;     
	   
	
	mapping(uint256 => mapping(uint256 => uint256)) public price_time_lists;
	 
	mapping(uint256 => mapping(uint256 => uint256)) public release_time_lists;
	mapping(uint256 => mapping(uint256 => uint256)) public release_amount_lists;
	
	 
	  
	 
	
	mapping(uint256 => mapping(uint256 => uint256)) public tmp_lists;
	
	
	
	uint public unlocked=1; 
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
	uint public unlocked_2=1;
	modifier lock_2() {
        require(unlocked_2 == 1, 'LOCKED');
        unlocked_2 = 0;
        _;
        unlocked_2 = 1;
    }
	
	// buy_start_time,uint buy_end_time,uint buy_min_amount,uint buy_max_amount,uint price_type,uint release_type
	function add_presale(uint data_id,address coin_address,uint amount,address buy_address,address sell_address,uint[] calldata arr,uint[] calldata price_lists,uint[] calldata release_lists)   public lock returns (uint) {
		
		IERC20(coin_address).transferFrom(msg.sender,address(this), amount);
		//>0
  		require( data_id ==index, 'data_id');
		
		address_index[msg.sender]=index;
		index_address[index]=msg.sender;

		coin_addr_lists[index]=coin_address;
		amount_lists[index]=amount;
		sell_amount_lists[index]=0;
		buy_amount_lists[index]=0;
		
		buy_address_lists[index]=buy_address;
		sell_address_lists[index]=sell_address;
		
		buy_start_time_lists[index]=arr[0];
		 
		buy_end_time_lists[index]=arr[1];
		
		buy_min_amount_lists[index]=arr[2];
		buy_max_amount_lists[index]=arr[3];
		price_start_lists[index]=arr[4];

		if(arr[9]==3){
			price_end_lists[index]=arr[5];
		}

		if(arr[10]==2 || arr[10]==3){
			release_daytime_lists[index]=arr[6];
		}
		if(arr[10]==3){
			release_daypre_lists[index]=arr[7];
			release_starttype_lists[index]=arr[8];

			require( arr[8] >0, 'more than 0');
		}
		 
		
		price_type_lists[index]=arr[9];
		release_type_lists[index]=arr[10];
		
		is_buy_type_lists[index]=arr[11];
		
		buy_time_lists[index][msg.sender]=block.timestamp;
		
		 
		
		
		//require(amount >0 && release_starttype_lists[index] >0 && price_type_lists[index]>0  && release_type_lists[index]>0 , 'more 0');
		require(amount >0 && arr[9] >0  && arr[10]>0 , 'more 0');
	 
		require(coin_address!=address(0x0) && address(buy_address)!=address(0x0)  , 'Address 0x');
		//Check price end and start 
		if(price_type_lists[index]==2 || price_type_lists[index]==3){
			require(price_end_lists[index] >0 ,'price_end >0');
			require(price_end_lists[index] >price_start_lists[index], 'price_end > price_start');
		}
		//check release 
		if(release_type_lists[index]==2 || release_type_lists[index]==3){
			require(release_daytime_lists[index] >0, 'release_time >0');
		}
		if(release_type_lists[index]==3){
			require(release_daypre_lists[index] >0, 'release_daypre >0');
			require(release_starttype_lists[index] >0 ,'release_starttype >0');
		}
		//check price what will change as time 
		uint tmp_time;
		uint tmp_amount;
		uint tmp_amount_all;
		if(price_type_lists[index]==4){
			 
			tmp_time=0;
			tmp_amount=price_start_lists[index];
			uint price_length=(price_lists.length)/2;
			for (uint i=0; i < (price_length) ; i++) {
				
				require(price_lists[i*2]>tmp_time ,'price_lists >0');
				require(price_lists[i*2+1]>tmp_amount ,'price_lists >0');
				
				price_time_lists[index][i]=price_lists[i*2];
				price_amount_lists[index][i]=price_lists[i*2+1];
				tmp_time=price_lists[i*2];
				tmp_amount=price_lists[i*2+1];
			}
			price_length_lists[index]=price_length;
		}
		//check release what will change as time 
		if(release_type_lists[index]==4){
			 
			tmp_time=0;
			tmp_amount=0;
			tmp_amount_all=0;
			uint release_length=(release_lists.length)/2;
			for (uint i=0; i < (release_length) ; i++) {
				
				require(release_lists[i*2]>tmp_time ,'release_lists >0');
				require(release_lists[i*2+1]>tmp_amount ,'release_lists >0');
				
				release_time_lists[index][i]=release_lists[i*2];
				release_amount_lists[index][i]=release_lists[i*2+1];
				
				 
			
				tmp_time=release_lists[i*2];
				tmp_amount=release_lists[i*2+1];
				tmp_amount_all=tmp_amount_all.add(tmp_amount);
			}
			require(tmp_amount_all==10000,'tmp_amount_all >0');
			release_length_lists[index]=release_length;
			
		}
		 

		 
		index++;
        return data_id;
    }
    
	function buy_presale(uint id,uint buy_amount,address to)   public  payable returns   (uint) {
	 	uint amount=0;
		uint to_amount=0;
		if(buy_address_lists[id]==address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)){
			amount=msg.value;
		}else{
			IERC20(coin_addr_lists[id]).transferFrom(msg.sender,address(this), buy_amount);
			amount=buy_amount;
		}
		if(price_type_lists[id]==1){
			to_amount=amount.mul(price_start_lists[id]);
		}
		if(price_type_lists[id]==2){ 
			uint left_amount=amount_lists[id].sub(sell_amount_lists[id]);

			uint k=price_start_lists[id].mul(amount_lists[id]);
			
			to_amount=left_amount.sub(k.div(buy_amount_lists[id].add(buy_amount)));
		}
    
   
		if(price_type_lists[id]==3){ 
            uint a=price_start_lists[id];
            uint b=sell_amount_lists[id];
			uint k=price_end_lists[id].div(price_start_lists[id]);
			uint max_sell_amount=amount_lists[id].mul(price_end_lists[id]);
			 
			uint has_amount=max_sell_amount.sub(b);
			     pre=has_amount.div(max_sell_amount);
			uint p1=k.mul(a).mul(pre);
			uint y1=p1.mul(b);
			
            uint tmp=b.add(amount);
			   	 has_amount=max_sell_amount.sub(tmp);
			     pre=has_amount.div(max_sell_amount);
			uint p2=k.mul(a).mul(pre);
			uint y2=p2.mul(b.add(amount));
			
				 to_amount=y2.sub(y1);
		}
		if(price_type_lists[id]==4){ 
			uint time=block.timestamp;
			uint price_length=price_length_lists[id];
			for (uint i=0; i < (price_length-1) ; i++) {
				if(time>=price_time_lists[id][i]){
					to_amount=amount.mul(price_amount_lists[id][i]);
				}
				 
			}
			if(to_amount==0){
				to_amount=amount.mul(price_start_lists[id]);
			}
		}
		if(release_type_lists[id]==1){ 
			IERC20(coin_addr_lists[id]).transfer(to,to_amount);
		}
		if(release_type_lists[id]==2 && block.timestamp>release_timetype_lists[id]){ 
			IERC20(coin_addr_lists[id]).transfer(to,to_amount);
		}
		if(release_type_lists[id]==3 || release_type_lists[id]==4 || (release_type_lists[id]==2 && block.timestamp<=release_timetype_lists[id])){ 
			user_amount_lists[msg.sender][id]=user_amount_lists[msg.sender][id].add(to_amount);
		}
		// buy min or max
		if(buy_min_amount_lists[id]>0 && is_buy_type_lists[id]==1){
			require(buy_min_amount_lists[id]<=to_amount ,'buy_min_amount');
		}
		if(buy_max_amount_lists[id]>0 && is_buy_type_lists[id]==1){
			require(buy_max_amount_lists[id]>=to_amount ,'buy_max_amount');
		}
		if(buy_min_amount_lists[id]>0 && is_buy_type_lists[id]==2){
			require(buy_min_amount_lists[id]<=buy_amount ,'buy_min_amount');
		}
		if(buy_max_amount_lists[id]>0 && is_buy_type_lists[id]==2){
			require(buy_max_amount_lists[id]>=buy_amount ,'buy_max_amount');
		}
		
		buy_amount_lists[id]=buy_amount_lists[id].add(buy_amount);
		sell_amount_lists[id]=sell_amount_lists[id].add(to_amount);
		
		
		 
		
		admin_amount_lists[index_address[index]][buy_address_lists[id]]=admin_amount_lists[index_address[index]][buy_address_lists[id]].add(buy_amount.mul(pre).div(10000));
		admin_amount_lists[to_address][buy_address_lists[id]]=admin_amount_lists[to_address][buy_address_lists[id]].add(buy_amount.mul((10000-pre)).div(10000));
		
		 
		return (amount);
		
    }
	 
	function get_sale_release(uint id,address to)  public returns (uint to_amount) {
		require(user_amount_lists[msg.sender][id]>0 ,'0');
		 
		if(release_type_lists[id]==2 && block.timestamp>release_timetype_lists[id]){ 
			to_amount=user_amount_lists[msg.sender][id];	 
		}
		if(release_type_lists[id]==3){ 
			uint day=0;
			if(release_starttype_lists[id]==1 && release_daytime_lists[id]>block.timestamp){
				day=block.timestamp.sub(release_daytime_lists[id]).div(86400);
			}
			if(release_starttype_lists[id]==2){
				day=block.timestamp.sub(buy_time_lists[id][msg.sender]).div(86400);
			}
			if(day>0){
				to_amount=day.mul(release_daypre_lists[id]);
				to_amount=user_amount_lists[msg.sender][id].mul(to_amount).div(10000);
				to_amount=to_amount.sub(user_getamount_lists[id][msg.sender]);
				
				user_getamount_lists[id][msg.sender]=user_amount_lists[msg.sender][id].mul(to_amount).div(10000);
			}
			 
		}
		if(release_type_lists[id]==4){ 
			
			uint time=block.timestamp;
			uint length=release_length_lists[id];
			for (uint i=0; i < (length-1) ; i++) {
				if(time>release_time_lists[id][i] ){
					to_amount=to_amount.add(release_amount_lists[id][i]);
				}
				 
			}
			if(to_amount>0){
				 
				to_amount=user_amount_lists[msg.sender][id].mul(to_amount).div(10000);
				to_amount=to_amount.sub(user_getamount_lists[id][msg.sender]);
				user_getamount_lists[id][msg.sender]=user_amount_lists[msg.sender][id].mul(to_amount).div(10000);
			}
		}
		
		require(to_amount>0 ,'0');
		 
		
		IERC20(coin_addr_lists[id]).transfer(to,to_amount);
		
		
    }
	function get_price(uint id,uint buy_amount)   public  payable returns   (uint) {
	 	uint amount=0;
		uint to_amount=0;
		amount=buy_amount;
		
		if(price_type_lists[id]==1){
			to_amount=amount.mul(price_start_lists[id]);
		}
		if(price_type_lists[id]==2){ 
			uint left_amount=amount_lists[id].sub(sell_amount_lists[id]);

			uint k=price_start_lists[id].mul(amount_lists[id]);
			
			to_amount=left_amount.sub(k.div(buy_amount_lists[id].add(buy_amount)));
		}
		if(price_type_lists[id]==3){ 
            uint a=price_start_lists[id];
            uint b=sell_amount_lists[id];
			uint k=price_end_lists[id].div(price_start_lists[id]);
			uint max_sell_amount=amount_lists[id].mul(price_end_lists[id]);
			 
			uint has_amount=max_sell_amount.sub(b);
			     pre=has_amount.div(max_sell_amount);
			uint p1=k.mul(a).mul(pre);
			uint y1=p1.mul(b);
			
            uint tmp=b.add(amount);
			   	 has_amount=max_sell_amount.sub(tmp);
			     pre=has_amount.div(max_sell_amount);
			uint p2=k.mul(a).mul(pre);
			uint y2=p2.mul(b.add(amount));
			
				 to_amount=y2.sub(y1);
		}
		if(price_type_lists[id]==4){ 
			uint time=block.timestamp;
			uint price_length=price_length_lists[id];
			for (uint i=0; i < (price_length-1) ; i++) {
				if(time>=price_time_lists[id][i]){
					to_amount=amount.mul(price_amount_lists[id][i]);
				}
				 
			}
			if(to_amount==0){
				to_amount=amount.mul(price_start_lists[id]);
			}
		}
		return to_amount;
		
	}
	
	function get_detail(uint id)   public view returns (address,uint,address) {
	 	address addr=index_address[id];
		uint amount=amount_lists[id];
		address sell_address=sell_address_lists[id];
		
		
		 
		return (addr,amount,sell_address);
		
    }
    function get_price_lists(uint id)   public view returns (uint[] memory,uint[] memory) {
	 	 
		uint price_length=price_length_lists[id];
		uint[] memory time_lists_tmp = new uint[](price_length);
        uint[] memory amount_lists_tmp = new uint[](price_length);
        for (uint i=0; i < (price_length-1) ; i++) {
            time_lists_tmp[i]=price_time_lists[id][i];
			amount_lists_tmp[i]=price_amount_lists[id][i];
        }
		 
	 
		return (time_lists_tmp,amount_lists_tmp);
		
    }
    function get_release_lists(uint id)   public view returns (uint[] memory,uint[] memory) {
	 	 
		uint price_length=release_length_lists[id];
		uint[] memory time_lists_tmp = new uint[](price_length);
        uint[] memory amount_lists_tmp = new uint[](price_length);
        for (uint i=0; i < (price_length) ; i++) {
            time_lists_tmp[i]=release_time_lists[id][i];
			amount_lists_tmp[i]=release_amount_lists[id][i];
        }
		 
	 
		return (time_lists_tmp,amount_lists_tmp);
		
    }
	
	function set_to_address(address _addr) external   onlyOwner  {
		to_address=_addr;
		
    }
	function set_pre(uint _val) external   onlyOwner  {
		pre=_val;
		
    }
	function withdraw_admin(address _address) external lock_2   {
		uint _amount=admin_amount_lists[msg.sender][_address];
		admin_amount_lists[msg.sender][_address]=0;
        IERC20(_address).transfer(msg.sender, _amount);
    }
	
	
	 
}