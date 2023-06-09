/**
 *Submitted for verification at Etherscan.io on 2019-09-24
*/

/**
 *Submitted for verification at Etherscan.io on 2019-03-11
*/

pragma solidity ^0.4.16;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
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


contract USDA is owned{
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals = 8;  
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Lock(address indexed ac, uint256 value, uint256 time);
    event Burn(uint256 amount);
    
    constructor() public {
        totalSupply = 100000 * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                
        name = "USDA";                                   
        symbol = "USDA";                               
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    
    function mintToken(uint256 mintedAmount) external onlyOwner {
        require(totalSupply + mintedAmount > totalSupply);
        require(balanceOf[owner] + mintedAmount > balanceOf[owner]);
        balanceOf[owner] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), owner, mintedAmount);
    }
    
    function burn (uint256 amount) external onlyOwner {
        require(balanceOf[msg.sender] >= amount);
        require(totalSupply >= amount);
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        emit Burn(amount);
    }

}