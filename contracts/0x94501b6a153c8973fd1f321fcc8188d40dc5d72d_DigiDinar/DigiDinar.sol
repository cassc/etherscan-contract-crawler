/**
 *Submitted for verification at Etherscan.io on 2019-12-05
*/

pragma solidity ^0.5.12;

// ----------------------------------------------------------------------------
// "DigiDinar Token contract"
//
// Symbol      : DDRT
// Name        : DigiDinar Token
// Total supply: 25000000
// Decimals    : 8
//
// Contract Developed by Kuwaiti Coin Limited
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

contract ERC20 {
  function balanceOf(address who) public view returns (uint256);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function transfer(address to, uint value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath { 
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

contract DigiDinar is ERC20 {

    using SafeMath for uint256;
    
    string public  name;
    string public  symbol;
    uint8 public  decimals;  
    address internal _admin;
    uint256 public _totalSupply;
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    constructor() public {  
        symbol = "DDRT";  
        name = "DigiDinar Token"; 
        decimals = 8;
        _totalSupply = 25000000 * 10**uint(decimals);
        _admin = msg.sender;
        balances[_admin] = _totalSupply;
        emit ERC20.Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
	    return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit ERC20.Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit ERC20.Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit ERC20.Transfer(owner, buyer, numTokens);
        return true;
    }

}