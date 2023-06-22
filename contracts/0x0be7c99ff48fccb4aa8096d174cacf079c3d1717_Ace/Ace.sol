/**
 *Submitted for verification at Etherscan.io on 2019-11-20
*/

pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------------------------
// Ace Token by Ace Limited.
// An ERC20 standard
//
contract ERC20Interface {
  // Get the total token supply
  function totalSupply() public constant returns (uint256 _totalSupply);

  // Get the account balance of another account with address _owner
  function balanceOf(address _owner) public constant returns (uint256 balance);

  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value) public returns (bool success);

  // transfer _value amount of token approved by address _from
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  // approve an address with _value amount of tokens
  function approve(address _spender, uint256 _value) public returns (bool success);

  // get remaining token approved by _owner to _spender
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

  // Triggered when tokens are transferred.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // Triggered whenever approve(address _spender, uint256 _value) is called.
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}
contract Ace is ERC20Interface {
  using SafeMath for uint;
  uint256 public constant decimals = 8;

  uint256 public constant oneAce = 10**8;
  uint256 public constant oneEth = 10**18;

  string public constant symbol = "ACEX";
  string public constant name = "ACEX";

  //initial selling
  bool public _selling = true;

  // total supply is 10^17 unit, equivalent to 10^9 Ace, 20bln
  uint256 public _totalSupply = oneAce.mul(2).mul(10 ** 9); //2*(10 ** 9) * oneAce;

  // _originalBuyPrice = how many ACE unit for 1 ETH
  // 1 ACE = 0.033 USD with the fixed rate
  // e.g. suppose 1 ETH = 142.49 USD, so _originalBuyPrice = 142.49 / 0.033 * oneAce = 4318 * oneAce = 4318 * 10**8 ACE unit
  uint256 public _originalBuyPrice = oneAce.mul(4318); //4318 * oneAce;

  // Owner of this contract
  address public owner;

  // Balances Ace for each account
  mapping(address => uint256) private balances;

  // Owner of account approves the transfer of an amount to another account
  mapping(address => mapping (address => uint256)) private allowed;

  // List of approved investors
  mapping(address => bool) private approvedInvestorList;

  // deposit
  mapping(address => uint256) private deposit;

  // icoPercent
  uint256 public _icoPercent = 10;

  // _icoSupply is the avalable unit. Initially, it is _totalSupply
  uint256 public _icoSupply = _totalSupply.mul(_icoPercent).div(100);

  // minimum buy 0.3 ETH, in wei
  uint256 public _minimumBuy = 3 * 10 ** 17;

  // maximum buy 25 ETH, in wei
  uint256 public _maximumBuy = 25 * oneEth;

  // totalTokenSold
  uint256 public totalTokenSold = 0;

  // tradable
  bool public tradable = false;

  // maximum token allowed to burn every time
  uint256 public _maximumBurn = 0;

  // Triggered whenever burn(uint256 _value) is called.
  event Burn(address indexed burner, uint256 value);
  // Triggered whenever turnOnSale()、turnOffSale() is called.
  event Sale(address indexed safer, bool value);
  // Triggered whenever turnOnTradable() is called.
  event Tradable(address indexed safer, bool value);
  //
  event ParamConfig(uint256 paramType, uint256 value);

  /**
   * Functions with this modifier can only be executed by the owner
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * Functions with this modifier check on sale status
   * Only allow sale if _selling is on
   */
  modifier onSale() {
    require(_selling);
    _;
  }

  /**
   * Functions with this modifier check the validity of address is investor
   */
  modifier validInvestor() {
    require(approvedInvestorList[msg.sender]);
    _;
  }

  /**
   * Functions with this modifier check the validity of msg value
   * value must greater than equal minimumBuyPrice
   * total deposit must less than equal maximumBuyPrice
   */
  modifier validValue(){
    // require value >= _minimumBuy AND total deposit of msg.sender <= maximumBuyPrice
    require ( (msg.value >= _minimumBuy) &&
      ( (deposit[msg.sender] + msg.value) <= _maximumBuy) );
    _;
  }

  /**
   * Functions with this modifier check the validity of address is not 0
   */
  modifier validAddress {
    require(address(0) != msg.sender);
    _;
  }

  /**
   *
   */
  modifier isTradable(){
    require(tradable == true || msg.sender == owner);
    _;
  }

  /// @dev Fallback function allows to buy ether.
  function()
  public
  payable {
    buyAce();
  }

  /// @dev buy function allows to buy ether. for using optional data
  function buyAce()
  public
  payable
  onSale
  validValue
  validInvestor {
    // (ETH from msg.sender in wei) * (how many ACE unit for 1 ETH) / (how many wei for 1 ETH)
    //uint256 requestedUnits = (msg.value * _originalBuyPrice) / 10**18;
    uint256 requestedUnits = msg.value.mul(_originalBuyPrice).div(oneEth);
    require(balances[owner] >= requestedUnits);
    // prepare transfer data
    balances[owner] = balances[owner].sub(requestedUnits);
    balances[msg.sender] = balances[owner].add(requestedUnits);
    // increase total deposit amount
    deposit[msg.sender] = deposit[msg.sender].add(msg.value);
    totalTokenSold = totalTokenSold.add(requestedUnits);
    // check total and auto turnOffSale
    if (totalTokenSold >= _icoSupply){
      _selling = false;
    }

    // submit transfer
    Transfer(owner, msg.sender, requestedUnits);
    owner.transfer(msg.value);
  }

  /// @dev Constructor
  function Ace()
  public {
    owner = msg.sender;
    setBuyPrice(_originalBuyPrice);
    balances[owner] = _totalSupply;
    Transfer(0x0, owner, _totalSupply);
  }

  /// @dev Gets totalSupply
  /// @return Total supply
  function totalSupply()
  public
  constant
  returns (uint256) {
    return _totalSupply;
  }

  /// @dev Enables sale
  function turnOnSale() onlyOwner
  public {
    _selling = true;
    Sale(msg.sender, true);
  }

  /// @dev Disables sale
  function turnOffSale() onlyOwner
  public {
    _selling = false;
    Sale(msg.sender, false);
  }

  function turnOnTradable()
  public
  onlyOwner{
    tradable = true;
    Tradable(msg.sender, true);
  }

  /// @dev set new icoPercent
  /// @param newIcoPercent new value of icoPercent
  function setIcoPercent(uint256 newIcoPercent)
  public
  onlyOwner {
    _icoPercent = newIcoPercent;
    //_icoSupply = _totalSupply * _icoPercent / 100;
    _icoSupply = _totalSupply.mul(_icoPercent).div(100);
    ParamConfig(1, _icoPercent);
  }

  /// @dev set new _minimumBuy
  /// @param newMinimumBuy new value of _minimumBuy
  function setMinimumBuy(uint256 newMinimumBuy)
  public
  onlyOwner {
    _minimumBuy = newMinimumBuy;
    ParamConfig(2, _minimumBuy);
  }

  /// @dev set new _maximumBuy
  /// @param newMaximumBuy new value of _maximumBuy
  function setMaximumBuy(uint256 newMaximumBuy)
  public
  onlyOwner {
    _maximumBuy = newMaximumBuy;
    ParamConfig(3, _maximumBuy);
  }

  /// @dev Updates buy price (owner ONLY)
  /// @param newBuyPrice New buy price (in unit)
  function setBuyPrice(uint256 newBuyPrice)
  onlyOwner
  public {
    require(newBuyPrice>0);

    // buy price = how many ACE unit for 1 ETH
    // 1 ACE = 0.012 USD with the fixed rate
    // e.g. suppose 1 ETH = 142.49 USD, so _originalBuyPrice = 142.49 / 0.033 * oneAce = 4318 * oneAce = 4318 * 10**8 ACE unit
    _originalBuyPrice = newBuyPrice;

    // control _maximumBuy_USD = 3,000 USD, Ace price is 0.033 USD
    // maximumBuy_Ace = 3000 / 0.033 = 90910 Ace = 90,910,00000000 unit
    // maximumETH = maximumBuy_Ace / _originalBuyPrice = 90,910,00000000 / 4,318,00000000
    // 90,910,00000000 / 4,318,00000000 ~ 21ETH => change to wei
    // so _maximumBuy = (how many wei for 1 ETH) * maximumBuy_Ace / _originalBuyPrice
    //_maximumBuy = (10**18) * 90910 * oneAce /_originalBuyPrice;
    _maximumBuy = oneAce.mul(90910).mul(oneEth).div(_originalBuyPrice) ;
    ParamConfig(4, _originalBuyPrice);
  }

  /// @dev Gets account's balance
  /// @param _addr Address of the account
  /// @return Account balance
  function balanceOf(address _addr)
  public
  constant
  returns (uint256) {
    return balances[_addr];
  }

  /// @dev check address is approved investor
  /// @param _addr address
  function isApprovedInvestor(address _addr)
  public
  constant
  returns (bool) {
    return approvedInvestorList[_addr];
  }

  /// @dev get ETH deposit
  /// @param _addr address get deposit
  /// @return amount deposit of an buyer
  function getDeposit(address _addr)
  public
  constant
  returns(uint256){
    return deposit[_addr];
  }

  /// @dev Adds list of new investors to the investors list and approve all
  /// @param newInvestorList Array of new investors addresses to be added
  function addInvestorList(address[] newInvestorList)
  onlyOwner
  public {
    // maximum 150 investors per transaction, to avoid out of gas issue
    require(newInvestorList.length <= 150);
    for (uint256 i = 0; i < newInvestorList.length; i++){
      approvedInvestorList[newInvestorList[i]] = true;
    }
  }

  /// @dev Removes list of investors from list
  /// @param investorList Array of addresses of investors to be removed
  function removeInvestorList(address[] investorList)
  onlyOwner
  public {
    // maximum 150 investors per transaction, to avoid out of gas issue
    require(investorList.length <= 150);
    for (uint256 i = 0; i < investorList.length; i++){
      approvedInvestorList[investorList[i]] = false;
    }
  }

  /// @dev Transfers the balance from msg.sender to an account
  /// @param _to Recipient address
  /// @param _amount Transfered amount in unit
  /// @return Transfer status
  function transfer(address _to, uint256 _amount)
  public
  isTradable
  validAddress
  returns (bool) {
    // if sender's balance has enough unit and amount >= 0,
    //      and the sum is not overflow,
    // then do transfer
    require(balances[msg.sender] >= _amount);
    require(_amount >= 0);
    require(balances[_to] + _amount > balances[_to]);
    require(_to != address(0));

    /*balances[msg.sender] -= _amount;
    balances[_to] += _amount;*/
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);

    Transfer(msg.sender, _to, _amount);
    return true;
  }

  // Send _value amount of tokens from address _from to address _to
  // The transferFrom method is used for a withdraw workflow, allowing contracts to send
  // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
  // fees in sub-currencies; the command should fail unless the _from account has
  // deliberately authorized the sender of the message via some mechanism; we propose
  // these standardized APIs for approval:
  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  )
  public
  isTradable
  validAddress
  returns (bool success) {
    require(balances[_from] >= _amount);
    require(allowed[_from][msg.sender] >= _amount);
    require(_amount > 0);
    require(balances[_to] + _amount > balances[_to]);
    require(_to != address(0));

    /*balances[_from] -= _amount;
    allowed[_from][msg.sender] -= _amount;
    balances[_to] += _amount;*/

    balances[_from] = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);

    Transfer(_from, _to, _amount);
    return true;
  }

  // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
  // If this function is called again it overwrites the current allowance with _value.
  function approve(address _spender, uint256 _amount)
  public
  isTradable
  validAddress
  returns (bool success) {
    // not allowed to overwrite unless the _amount is 0 to prevent the race condition attack
    // caller must first reduce the spender's allowance to 0 and set the desired value afterwards
    require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
    require(_spender != address(0));
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  // get allowance
  function allowance(address _owner, address _spender)
  public
  constant
  returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /// @dev Withdraws Ether in contract (Owner only)
  /// @return Status of withdrawal
  function withdraw() onlyOwner
  public
  returns (bool) {
    return owner.send(this.balance);
  }

  /// @dev set new _maximumBurn
  /// @param newMaximumBurn new value of _maximumBurn
  function setMaximumBurn(uint256 newMaximumBurn)
  public
  onlyOwner {
    _maximumBurn = newMaximumBurn;
  }

  /// @dev Burns a specific amount of tokens.
  /// @param _value The amount of token to be burned.
  function burn(uint256 _value)
  public
  onlyOwner {
    require(_value > 0 && _value <= _maximumBurn);
    require(balances[msg.sender] >= _value);
    require(_totalSupply >= _value);
    //balances[msg.sender] -= _value;
    balances[msg.sender] = balances[msg.sender].sub(_value);
    _totalSupply = _totalSupply.sub(_value);
    //balances[0x0] += _value;
    //Transfer(msg.sender, 0x0, _value);
    Burn(msg.sender, _value);
  }
}