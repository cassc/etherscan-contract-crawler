/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

pragma solidity ^0.6.0;
 
interface m32V1 {
  function balanceOf ( address _address  ) external returns ( uint );
  function getCostPerUnit() external returns ( uint );
} 

contract Minereum32 {
    //Version 2 - Migration on June 14, 2023
    string public symbol = "M32";
    string public name = "Minereum32 - Only 32 Tokens Supply";
    uint8 public constant decimals = 18;
    uint256 public _totalSupply = 32000000000000000000;
	uint256 public _totalMint = 0;
	uint256 public _totalMigrated = 0;
	uint256 public _totalAirdropped = 0;
	uint256 public _totalAirdropSent = 0;
	uint256 public airdropAmount = 1;
	uint256 public divideBy = 10000000;
	uint256 public costPerUnit = 0;
    address public owner;
	address public outerAddress;
	address public addressCaller;
	m32V1 public _m32v1;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 
    mapping(address => uint256) balances;
 
    mapping(address => mapping (address => uint256)) allowed;
	
	mapping(address => bool) registeredAddress;
 
	constructor(address previousContract) public {
        owner = msg.sender; 
		outerAddress = msg.sender;
		addressCaller = msg.sender;
		balances[address(this)] = _totalSupply;
		registeredAddress[address(this)] = true;
		
		//Version 2 - Migration on June 14, 2023
        //Balances Migration from Previous Contract V1        
		_m32v1 = m32V1(previousContract);
		costPerUnit = _m32v1.getCostPerUnit();
		
		if(!transferMigration(0xcAC84E716a452829B23DD321979114599Dc8eD63)) revert();
		if(!transferMigration(0xe01E33a74C5175614122ef1D2E17a9672D9e54E5)) revert();		
    }
 
    function totalSupply() public view returns (uint256 supply) {        
        return _totalSupply;
    }
 
    function balanceOf(address _owner) public view returns (uint256 balance) {
        if (registeredAddress[_owner])
			return balances[_owner];
		else
			return airdropAmount;
    }
 
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        
		if (!registeredAddress[msg.sender]) 
		{
			checkSupply(airdropAmount);
			balances[msg.sender] = airdropAmount;
			registeredAddress[msg.sender] = true;
			_totalAirdropped += airdropAmount;
		}
		
		if (!registeredAddress[_to]) 
		{
			checkSupply(airdropAmount);
			balances[_to] = airdropAmount;
			registeredAddress[_to] = true;
			_totalAirdropped += airdropAmount;
		}		
		
		if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferMint(address _to, uint256 _amount) private returns (bool success) {
        if (balances[address(this)] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[address(this)] -= _amount;
			
			if (!registeredAddress[_to]) 
			{
				checkSupply(airdropAmount);
				balances[_to] += _amount + airdropAmount;
				registeredAddress[_to] = true;
				_totalAirdropped += airdropAmount;
			}
			else
				balances[_to] += _amount;			
            
            emit Transfer(address(this), _to, _amount);
            return true;
        } else {
            return false;
        }
    }
	
	function transferMigration(address _to) private returns (bool success) {
		//Version 2 - Migration on June 14, 2023
        //For Balance Migration from Previous Contract V1
        uint256 _amount = _m32v1.balanceOf(_to);
        if (balances[address(this)] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[address(this)] -= _amount;
            balances[_to] += _amount;			
			registeredAddress[_to] = true;			
            emit Transfer(address(this), _to, _amount);
            _totalMigrated += _amount; 
			_totalMint += _amount;
            return true;
        } else {
            return false;
        }
    }
 
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool success) {
		
		if (!registeredAddress[_from]) 
		{
			checkSupply(airdropAmount);
			balances[_from] = airdropAmount;
			registeredAddress[_from] = true;
			_totalAirdropped += airdropAmount;
		}
		
		if (!registeredAddress[_to]) 
		{
			checkSupply(airdropAmount);
			balances[_to] = airdropAmount;
			registeredAddress[_to] = true;
			_totalAirdropped += airdropAmount;
		}		
		
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
	
	function release() public
	{
		address payable add = payable(outerAddress);
		if(!add.send(address(this).balance)) revert();
	}
	
	function checkSupply(uint _amount) private {
        if ((_totalMint + _totalAirdropped + _amount) > _totalSupply)
			airdropAmount = 0;		
    }
	
	function setOuterAddress(address _address) public
	{
		if(msg.sender == owner)
			outerAddress = _address;
		else
			revert();
	}
	
	function setAddressCaller(address _address) public
	{
		if(msg.sender == owner)
			addressCaller = _address;
		else
			revert();
	}
	
	function setCostPerUnit(uint value) public
	{
		if(msg.sender == owner)
			costPerUnit = value;
		else
			revert();
	}
	
	function setDivideBy(uint value) public
	{
		if(msg.sender == owner)
			divideBy = value;
		else
			revert();
	}
	
	function mint(uint quantity) public payable {		
		if (quantity == 0) revert();
	
		uint amount = (quantity * (_totalSupply / divideBy));
		
		if (msg.value == (quantity * costPerUnit))
		{
			if (!transferMint(msg.sender, amount)) revert('transfer error');
            _totalMint += amount;            
		}
		else
		{
			revert('invalid value');
		}		
	}
	
	function registerAddressesValue(address[] memory _addressList) public {
		uint i = 0;
		if (msg.sender != addressCaller) revert(); 
		_totalAirdropSent += (_addressList.length * airdropAmount);
		balances[address(this)] -= _addressList.length * airdropAmount;
		while(i < _addressList.length)
		{
			emit Transfer(address(this), _addressList[i], airdropAmount);
			i++;
		}
	}	
	
	function setTokenName(string memory value) public
	{
		if(msg.sender == owner)
			name = value;
		else
			revert();
	}
	
	function setTokenSymbol(string memory value) public
	{
		if(msg.sender == owner)
			symbol = value;
		else
			revert();
	}
	
	function setAirdropAmount(uint value) public
	{
		if(msg.sender == owner)
			airdropAmount = value;
		else
			revert();
	}
	
	function getCostPerUnit() public view returns (uint _costPerUnit) 
	{
		return costPerUnit;
	
	}
	
	function finalCost(uint quantity) public view returns (uint _cost) 
	{
		return quantity * costPerUnit;
	}
	
	function getMinted() public view returns (uint _value) 
	{
		return _totalMint;
	}
	
	function getMigrated() public view returns (uint _value) 
	{
		return _totalMigrated;
	}
	
	function getAirdropped() public view returns (uint _value) 
	{
		return _totalAirdropped;
	}
	
	function getAirdropSent() public view returns (uint _value) 
	{
		return _totalAirdropSent;
	}
	
	function unitValue() public view returns (uint _value) 
	{
		return _totalSupply / divideBy;
	}
}