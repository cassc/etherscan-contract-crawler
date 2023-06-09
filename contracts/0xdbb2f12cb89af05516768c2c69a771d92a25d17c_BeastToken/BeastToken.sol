/**
 *Submitted for verification at Etherscan.io on 2020-12-28
*/

// Beast DAO - Unleash the DeFi Beast. - https://beast.finance
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
  
  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}



contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract BeastToken is ERC20Interface, Owned {
    using SafeMath for uint256;
    string public symbol = "BEAST";
    string public  name = "Beast DAO";
    uint256 public decimals = 18;
    uint256 _totalSupply = 500000 * 10 ** (decimals); // 500k
    address beasts;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    constructor() public {
        balances[owner] = balances[owner].add(_totalSupply);
        emit Transfer(address(0),owner, _totalSupply);
    }
    
    function UnleashTheBeast(address _address) external onlyOwner{
        require(_address != address(0), "Invalid address");
        beasts = _address;
    }

// To ensure the safety and liquidity of our users, the BeastDAO token does not have a dev mint function, this makes it impossible for us to mint anymore tokens.

    function BurnTokens(uint256 _amount) external {
        _burn(_amount, msg.sender);
    }

    function _burn(uint256 _amount, address _account) internal {
        require(balances[_account] >= _amount, "insufficient account balance");
        _totalSupply = _totalSupply.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }
    
    function totalSupply() public override view returns (uint256){
       return _totalSupply; 
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens) public override returns  (bool success) {
        require(address(to) != address(0));
        require(balances[msg.sender] >= tokens );
        require(balances[to].add(tokens) >= balances[to]);
            
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender,to,tokens);
        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success){
        require(tokens <= allowed[from][msg.sender]); //check allowance
        require(balances[from] >= tokens);
        require(from != address(0), "Invalid address");
        require(to != address(0), "Invalid address");
        
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from,to,tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}