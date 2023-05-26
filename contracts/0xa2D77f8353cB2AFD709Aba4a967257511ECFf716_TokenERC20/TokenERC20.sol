/**
 *Submitted for verification at Etherscan.io on 2020-07-08
*/

pragma solidity ^0.4.25;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract owned {
	address public owner;

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
    	require(msg.sender == owner);
    	_;
	}

}

library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        
        return c;
    }

}

contract TokenERC20 is owned {
    
    using SafeMath for uint256;

	string public name;
	string public symbol;
	uint8 public decimals = 8;
	uint256 public totalSupply;

	mapping (address => uint256) public balanceOf;
	mapping (address => mapping(address => uint256)) public allowance;
	
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event Burn(address indexed from, address indexed to, uint256 value);

	constructor(uint256 initialSupply, string tokenName, string tokenSymbol) public {
			totalSupply = initialSupply*10**uint256(decimals);
			balanceOf[msg.sender] = totalSupply;
			emit Transfer(0x0, msg.sender, totalSupply);
			name = tokenName;
			symbol = tokenSymbol;
	}
	
    function _transfer(address _from, address _to, uint _value) internal {
    	
    	require(_to !=0x0);
    	require(balanceOf[_from] >= _value);
    	require(balanceOf[_to].add(_value) >= balanceOf[_to]);
    	
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
    
    	balanceOf[_from] = balanceOf[_from].sub(_value);
    	balanceOf[_to] = balanceOf[_to].add(_value);
    	
    	emit Transfer(_from, _to, _value);
    	assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    
    }

    function transfer(address _to, uint256 _value) public returns (bool sucess){
    	
    	_transfer(msg.sender, _to, _value);
    	return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool sucess){
    	
    	require(_value <= allowance[_from][msg.sender]);
    	allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    	_transfer(_from, _to, _value);
    	return true;
    
    }
    
    function approve(address _spender, uint256 _value) public returns (bool sucess){
    	
    	allowance[msg.sender][_spender] = _value;
    	emit Approval(msg.sender, _spender, _value);
    	return true;
    
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    
   function burn(uint256 _value) onlyOwner public returns (bool sucess){
    	require(balanceOf[msg.sender] >= _value);
    
    	balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    	totalSupply = totalSupply.sub(_value);
    	emit Transfer(msg.sender, address(0), _value);
    	return true;
    }
    
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool sucess){
    	require(balanceOf[_from] >= _value);
    	require(_value <= allowance[_from][msg.sender]);
    
    	balanceOf[_from] = balanceOf[_from].sub(_value);
    	allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    	totalSupply = totalSupply.sub(_value);
    	emit Transfer(msg.sender, address(0), _value);
    	return true;
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
    	balanceOf[target] = balanceOf[target].add(mintedAmount);
    	totalSupply = totalSupply.add(mintedAmount);
    	emit Transfer(address(0), target, mintedAmount);
    }
    
}