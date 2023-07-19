/**
 *Submitted for verification at Etherscan.io on 2019-09-20
*/

pragma solidity ^0.4.24;

contract ERC20 {
  function totalSupply() public constant returns (uint256);

  function balanceOf(address _addr) public constant returns (uint256);

  function allowance(address _addr, address _spender) public constant returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _fromValue,uint256 _toValue) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);
    return c;
  }
}


contract FBT is ERC20 {
  using SafeMath for uint256;
  address public owner;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  string public symbol;
  string public  name;
  uint256 public decimals;
  uint256 _totalSupply;

  constructor() public {
	owner = msg.sender;
    symbol = "FBT";
    name = "FANBI TOKEN";
    decimals = 6;

    _totalSupply = 5*(10**15);
    balances[owner] = _totalSupply;
  }

  function totalSupply() public  constant returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address _addr) public  constant returns (uint256) {
    return balances[_addr];
  }

  function allowance(address _addr, address _spender) public  constant returns (uint256) {
    return allowed[_addr][_spender];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _fromValue, uint256 _toValue) public returns (bool) {
    require(_spender != address(0));
    require(allowed[msg.sender][_spender] ==_fromValue);
    allowed[msg.sender][_spender] = _toValue;
    emit Approval(msg.sender, _spender, _toValue);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
}