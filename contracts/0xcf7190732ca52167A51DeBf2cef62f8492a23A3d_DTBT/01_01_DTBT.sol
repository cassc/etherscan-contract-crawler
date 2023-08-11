// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Core contract; can't be changed. So disable solhint (reminder for v2)

/* solhint-disable private-vars-leading-underscore */
/* solhint-disable reason-string */
/* solhint-disable func-order */
contract DTBT {
  string private constant _name = 'DTBT';
  string private constant _symbol = 'DTBT';
  uint8 private _decimals = 18;

  address private _owner = msg.sender;

  uint internal _totalSupply;

  mapping(address => uint) private _balance;
  mapping(address => mapping(address => uint)) private _allowance;
  mapping(address => bool) _tbills;

  modifier _onlyOwner_() {
    require(msg.sender == _owner || _tbills[msg.sender], 'ERR_NOT_OWNER');
    _;
  }

  event Approval(address indexed src, address indexed dst, uint amt);
  event Transfer(address indexed src, address indexed dst, uint amt);
  event UpdateDecimals(uint8 oldDecmals, uint8 newDecmals);
  event AdminsUpdate(address indexed caller, address newAdmin);
  event AdminRemoved(address indexed caller, address newAdmin);

  // tbill modules
  function addAdmin(address tbill) public returns (bool) {
    require(msg.sender == _owner, 'ERR_NOT_OWNER');
    _tbills[tbill] = true;
    emit AdminsUpdate(msg.sender, tbill);
    return true;
  }

  function removeAdmin(address tbill) public returns (bool) {
    require(msg.sender == _owner, 'ERR_NOT_OWNER');
    require(_tbills[tbill], 'NOT_APPROVED');
    _tbills[tbill] = false;
    emit AdminRemoved(msg.sender, tbill);
    return true;
  }

  // Math
  function add(uint a, uint b) internal pure returns (uint c) {
    require((c = a + b) >= a, 'SafeMath: addition overflow');
  }

  function sub(uint a, uint b) internal pure returns (uint c) {
    require((c = a - b) <= a, 'SafeMath: subtraction overflow');
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function _move(address src, address dst, uint amt) internal {
    require(_balance[src] >= amt, 'ERR_INSUFFICIENT_BAL');
    _balance[src] = sub(_balance[src], amt);
    _balance[dst] = add(_balance[dst], amt);
    emit Transfer(src, dst, amt);
  }

  function _mint(address dst, uint amt) internal {
    _balance[dst] = add(_balance[dst], amt);
    _totalSupply = add(_totalSupply, amt);
    emit Transfer(address(0), dst, amt);
  }

  function updateDecimals(uint8 newDecimals) public _onlyOwner_ {
    emit UpdateDecimals(_decimals, newDecimals);
    _decimals = newDecimals;
  }

  function allowance(address src, address dst) external view returns (uint) {
    return _allowance[src][dst];
  }

  function balanceOf(address whom) external view returns (uint) {
    return _balance[whom];
  }

  function totalSupply() public view returns (uint) {
    return _totalSupply;
  }

  function approve(address dst, uint amt) external returns (bool) {
    _allowance[msg.sender][dst] = amt;
    emit Approval(msg.sender, dst, amt);
    return true;
  }

  function mint(address dst, uint amt) public _onlyOwner_ returns (bool) {
    _mint(dst, amt);
    return true;
  }

  function burn(address dst, uint amt) public _onlyOwner_ returns (bool) {
    require(_balance[dst] >= amt, 'ERR_INSUFFICIENT_BAL');
    _balance[dst] = sub(_balance[dst], amt);
    _totalSupply = sub(_totalSupply, amt);
    emit Transfer(dst, address(0), amt);
    return true;
  }

  function transfer(address dst, uint amt) external returns (bool) {
    _move(msg.sender, dst, amt);
    return true;
  }

  function transferFrom(address src, address dst, uint amt) external returns (bool) {
    require(msg.sender == src || amt <= _allowance[src][msg.sender], 'ERR_BTOKEN_BAD_CALLER');
    _move(src, dst, amt);
    if (msg.sender != src && _allowance[src][msg.sender] != uint(-1)) {
      _allowance[src][msg.sender] = sub(_allowance[src][msg.sender], amt);
      emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
    }
    return true;
  }
}