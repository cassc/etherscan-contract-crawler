/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
  constructor () internal {}

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this;
    return msg.data;
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Blacklistable is Ownable {
  mapping (address => bool) public isBlacklisted;

  event AddedBlacklist(address _user);
  event RemovedBlacklist(address _user);

  modifier onlyNotBlacklisted() {
    require(isBlacklisted[_msgSender()] == false, "Blacklistable: caller is blacklisted");
    _;
  }

  function getBlacklistStatus(address account) external view returns (bool) {
    return isBlacklisted[account];
  }

  function addBlacklist (address account) public onlyOwner {
    isBlacklisted[account] = true;
    emit AddedBlacklist(account);
  }

  function removeBlacklist (address account) public onlyOwner {
    isBlacklisted[account] = false;
    emit RemovedBlacklist(account);
  }
}

contract XWGToken is Context, IBEP20, Ownable, Blacklistable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  mapping(address => bool) private _minters;

  event MinterAdded(address indexed minter);
  event MinterRemoved(address indexed minter);

  constructor() public {
    _name = "XWG";
    _symbol = "XWG";
    _decimals = 18;
  }

  modifier onlyMinter() {
      require(_minters[_msgSender()], "BEP20: caller is not the owner");
      _;
  }

  function getOwner() override external view returns (address) {
    return owner();
  }

  function decimals() override external view returns (uint8) {
    return _decimals;
  }

  function symbol() override external view returns (string memory) {
    return _symbol;
  }

  function name() override external view returns (string memory) {
    return _name;
  }

  function totalSupply() override external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) override external view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) override public onlyNotBlacklisted returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) override public onlyNotBlacklisted returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function allowance(address owner, address spender) override external view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) override public onlyNotBlacklisted returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public onlyNotBlacklisted returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public onlyNotBlacklisted returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function addMinter(address minter) external onlyOwner {
      _minters[minter] = true;
      emit MinterAdded(minter);
  }

  function removeMinter(address minter) external onlyOwner {
      _minters[minter] = false;
      emit MinterRemoved(minter);
  }

  function isMinter(address minter) external view returns(bool) {
      return _minters[minter];
  }

  function mint(address to, uint256 amount) external onlyMinter returns (bool) {
    _mint(to, amount);
    return true;
  }

  function burn(uint256 amount) external returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }

  function batchTransfer(address[] memory recipients, uint256[] memory amounts) public onlyNotBlacklisted returns (bool) {
    require(recipients.length == amounts.length);
    for (uint256 i = 0; i < recipients.length; i++) {
      require(transfer(recipients[i], amounts[i]));
    }
    return true;
  }

  function batchTransferFrom(address sender, address[] memory recipients, uint256[] memory amounts) public onlyNotBlacklisted returns (bool) {
    require(recipients.length == amounts.length);
    for (uint256 i = 0; i < amounts.length; i++) {
      require(transferFrom(sender, recipients[i], amounts[i]));
    }
    return true;
  }

  function batchTransferFromMany(address[] memory senders, address recipient, uint256[] memory amounts) public onlyNotBlacklisted returns (bool) {
    require(senders.length == amounts.length);
    for (uint256 i = 0; i < amounts.length; i++) {
      require(transferFrom(senders[i], recipient, amounts[i]));
    }
    return true;
  }

  function batchTransferFromManyToMany(address[] memory senders, address[] memory recipients, uint256[] memory amounts) public onlyNotBlacklisted returns (bool) {
    require(senders.length == recipients.length);
    require(senders.length == amounts.length);
    for (uint i = 0; i < amounts.length; i++) {
      require(transferFrom(senders[i], recipients[i], amounts[i]));
    }
    return true;
  }

  function batchApprove(address[] memory spenders, uint256[] memory amounts) public onlyNotBlacklisted returns (bool) {
    require(spenders.length == amounts.length);
    for (uint256 i = 0; i < amounts.length; i++) {
      require(approve(spenders[i], amounts[i]));
    }
    return true;
  }

  function batchIncreaseAllowance(address[] memory spenders, uint256[] memory addedValues) public onlyNotBlacklisted returns (bool) {
    require(spenders.length == addedValues.length);
    for (uint256 i = 0; i < addedValues.length; i++) {
      require(increaseAllowance(spenders[i], addedValues[i]));
    }
    return true;
  }

  function batchDecreaseAllowance(address[] memory spenders, uint256[] memory subtractedValues) public onlyNotBlacklisted returns (bool) {
    require(spenders.length == subtractedValues.length);
    for (uint256 i = 0; i < subtractedValues.length; i++) {
      require(decreaseAllowance(spenders[i], subtractedValues[i]));
    }
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal {
      require(account != address(0), "ERC20: mint to the zero address");

      _totalSupply = _totalSupply.add(amount);
      _balances[account] = _balances[account].add(amount);
      emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}