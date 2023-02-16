// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BNum.sol";

contract BTokenBase is BNum {
  mapping(address => uint256) internal _balance;
  mapping(address => mapping(address => uint256)) internal _allowance;
  uint256 internal _totalSupply;

  function _onTransfer(address from, address to, uint256 amount) internal virtual {}

  function _mint(uint256 amt) internal {
    address this_ = address(this);
    _balance[this_] = badd(_balance[this_], amt);
    _totalSupply = badd(_totalSupply, amt);
    _onTransfer(address(0), this_, amt);
  }

  function _burn(uint256 amt) internal {
    address this_ = address(this);
    require(_balance[this_] >= amt, "DexETF: insufficient balance");
    _balance[this_] = bsub(_balance[this_], amt);
    _totalSupply = bsub(_totalSupply, amt);
    _onTransfer(this_, address(0), amt);
  }

  function _move(address src, address dst, uint256 amt) internal {
    require(_balance[src] >= amt, "DexETF: insufficient balance");
    _balance[src] = bsub(_balance[src], amt);
    _balance[dst] = badd(_balance[dst], amt);
    _onTransfer(src, dst, amt);
  }

  function _push(address to, uint256 amt) internal {
    _move(address(this), to, amt);
  }

  function _pull(address from, uint256 amt) internal {
    _move(from, address(this), amt);
  }
}


contract BToken is BTokenBase, IERC20 {
  uint8 private constant DECIMALS = 18;
  string private _name;
  string private _symbol;

  function _initializeToken(string memory name_, string memory symbol_) internal {
    require(
      bytes(_name).length == 0 &&
      bytes(name_).length != 0 &&
      bytes(symbol_).length != 0,
      "DexETF: BToken already initialized"
    );
    _name = name_;
    _symbol = symbol_;
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function decimals() external pure returns (uint8) {
    return DECIMALS;
  }

  function allowance(address owner, address spender) external override(IERC20) view returns (uint256) {
    return _allowance[owner][spender];
  }

  function balanceOf(address account) external override(IERC20) view returns (uint256) {
    return _balance[account];
  }

  function totalSupply() public override(IERC20) view returns (uint256) {
    return _totalSupply;
  }

  function approve(address spender, uint256 amount) external override(IERC20) returns (bool) {
    address caller = msg.sender;
    _allowance[caller][spender] = amount;
    emit Approval(caller, spender, amount);
    return true;
  }

  function increaseApproval(address dst, uint256 amt) external returns (bool) {
    address caller = msg.sender;
    _allowance[caller][dst] = badd(_allowance[caller][dst], amt);
    emit Approval(caller, dst, _allowance[caller][dst]);
    return true;
  }

  function decreaseApproval(address dst, uint256 amt) external returns (bool) {
    address caller = msg.sender;
    uint256 oldValue = _allowance[caller][dst];
    if (amt > oldValue) {
      _allowance[caller][dst] = 0;
    } else {
      _allowance[caller][dst] = bsub(oldValue, amt);
    }
    emit Approval(caller, dst, _allowance[caller][dst]);
    return true;
  }

  function transfer(address recipient, uint256 amount) external override(IERC20) returns (bool) {
    _move(msg.sender, recipient, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override(IERC20) returns (bool) {
    address caller = msg.sender;
    require(caller == sender || amount <= _allowance[sender][caller], "DexETF: BToken bad caller");
    _move(sender, recipient, amount);
    if (caller != sender && _allowance[sender][caller] != type(uint256).max) {
      _allowance[sender][caller] = bsub(_allowance[sender][caller], amount);
      emit Approval(caller, recipient, _allowance[sender][caller]);
    }
    return true;
  }

  function _onTransfer(address from, address to, uint256 amount) internal override {
    emit Transfer(from, to, amount);
  }
}