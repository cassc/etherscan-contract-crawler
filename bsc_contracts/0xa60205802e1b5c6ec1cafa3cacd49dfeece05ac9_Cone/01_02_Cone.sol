// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./02_02_IERC20.sol";

contract Cone is IERC20 {

  string public constant symbol = "CONE";
  string public constant name = "Cone token";
  uint8 public constant decimals = 18;
  uint public override totalSupply = 0;

  mapping(address => uint) public override balanceOf;
  mapping(address => mapping(address => uint)) public override allowance;

  address public minter;

  constructor() {
    minter = msg.sender;
    _mint(msg.sender, 0);
  }

  // No checks as its meant to be once off to set minting rights to Minter
  function setMinter(address _minter) external {
    require(msg.sender == minter, "CONE: Not minter");
    minter = _minter;
  }

  function approve(address _spender, uint _value) external override returns (bool) {
    require(_spender != address(0), "CONE: Approve to the zero address");
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function _mint(address _to, uint _amount) internal returns (bool) {
    require(_to != address(0), "CONE: Mint to the zero address");
    balanceOf[_to] += _amount;
    totalSupply += _amount;
    emit Transfer(address(0x0), _to, _amount);
    return true;
  }

  function _transfer(address _from, address _to, uint _value) internal returns (bool) {
    require(_to != address(0), "CONE: Transfer to the zero address");

    uint fromBalance = balanceOf[_from];
    require(fromBalance >= _value, "CONE: Transfer amount exceeds balance");
  unchecked {
    balanceOf[_from] = fromBalance - _value;
  }

    balanceOf[_to] += _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function transfer(address _to, uint _value) external override returns (bool) {
    return _transfer(msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) external override returns (bool) {
    address spender = msg.sender;
    uint spenderAllowance = allowance[_from][spender];
    if (spenderAllowance != type(uint).max) {
      require(spenderAllowance >= _value, "CONE: Insufficient allowance");
    unchecked {
      uint newAllowance = spenderAllowance - _value;
      allowance[_from][spender] = newAllowance;
      emit Approval(_from, spender, newAllowance);
    }
    }
    return _transfer(_from, _to, _value);
  }

  function mint(address account, uint amount) external returns (bool) {
    require(msg.sender == minter, "CONE: Not minter");
    _mint(account, amount);
    return true;
  }
}