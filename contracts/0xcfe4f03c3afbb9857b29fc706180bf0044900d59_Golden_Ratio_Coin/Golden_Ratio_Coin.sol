/**
 *Submitted for verification at Etherscan.io on 2019-12-05
*/

pragma solidity ^0.5.12;

// ----------------------------------------------------------------------------
// "Golden Ratio Coin Token contract"
//
// Symbol      : GOLDR
// Name        : Golden Ratio Coin
// Total supply: 1618034
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

contract Golden_Ratio_Coin is ERC20 {

    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals;  
    address internal _admin;
    uint256 public _totalSupply;
    uint256 internal collateralLimit;
    
    mapping(address => uint256) balances;
    mapping(address => uint256) public collateralBalance;
    mapping(address => mapping (address => uint256)) allowed;

    constructor() public {  
        symbol = "GOLDR";  
        name = "Golden Ratio Coin"; 
        decimals = 8;
        _totalSupply = 1618034 * 10**uint(decimals);
        _admin = msg.sender;
        initial();
    }
    
    modifier onlyOwner(){
        require(msg.sender == _admin);
        _;
    }
    
    function initial() internal{
        balances[_admin] = 300000 * 10**uint(decimals);
        emit ERC20.Transfer(address(0), msg.sender, balances[_admin]);
        balances[address(this)] = 1318034 * 10**uint(decimals);
        collateralLimit  = 5000 * 10**uint(decimals);
    }

    function totalSupply() public view returns (uint256) {
	    return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    
    function setCollateralLimit(uint256 _amount) public onlyOwner returns (bool) {
        require(_amount > 0);
        collateralLimit = _amount * 10**uint(decimals);
        return true;
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        require(receiver != address(0));
        
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
    
    function fromContract(address receiver, uint _amount) public onlyOwner returns (bool) {
        require(receiver != address(0));
        require( _amount > 0 );
        
        balances[address(this)] = balances[address(this)].sub(_amount);
        balances[receiver] = balances[receiver].add(_amount);
        emit ERC20.Transfer(address(this), receiver, _amount);
        return true;
    }
    
    function mint(address _receiver, uint256 _amount) public onlyOwner returns (bool) {
        require( _amount > 0 );
        require(_receiver != address(0));
        require(balances[_receiver] >= collateralLimit);

        _totalSupply = _totalSupply.add(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        return true;
    }
    
    function lockTokens(uint256 _amount) public returns(bool){
        require( balances[msg.sender]>=_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        collateralBalance[msg.sender] = collateralBalance[msg.sender].add(_amount);
        return true;
    }
    
    function unlockTokens(uint256 _amount) onlyOwner public returns (bool) {
        require(collateralLimit >= _amount);
        balances[msg.sender] = balances[msg.sender].add( _amount);
        collateralBalance[msg.sender] = collateralBalance[msg.sender].sub(_amount);       
        return true;
    }
}