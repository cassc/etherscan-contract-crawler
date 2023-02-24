// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./libs/zeppelin/token/BEP20/IBEP20.sol";
import "./interfaces/IStorage.sol";

contract Demo is IBEP20 {
  string public constant name = "Demo";
  string public constant symbol = "DEMO";
  uint public constant decimals = 18;

  uint public totalSupply = 1e24;

  mapping (address => uint) internal _balances;
  mapping (address => mapping (address => uint)) private _allowed;
  IStorage private storageContract;

  constructor() {
    _mint(msg.sender, totalSupply);
  }

  function balanceOf(address _owner) override external view returns (uint) {
    return _balances[_owner];
  }

  function allowance(address _owner, address _spender) override external view returns (uint) {
    return _allowed[_owner][_spender];
  }

  function transfer(address _to, uint _value) override external returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) override external returns (bool) {
    _approve(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) override external returns (bool) {
    _transfer(_from, _to, _value);
    _approve(_from, msg.sender, _allowed[_from][msg.sender] - _value);
    return true;
  }

  function increaseAllowance(address _spender, uint _addedValue) external returns (bool) {
    _approve(msg.sender, _spender, _allowed[msg.sender][_spender] + _addedValue);
    return true;
  }

  function decreaseAllowance(address _spender, uint _subtractedValue) external returns (bool) {
    _approve(msg.sender, _spender, _allowed[msg.sender][_spender] - _subtractedValue);
    return true;
  }

  function burn(uint _amount) external {
    _balances[msg.sender] = _balances[msg.sender] - _amount;
    totalSupply = totalSupply - _amount;
    emit Transfer(msg.sender, address(0), _amount);
  }

  function _transfer(address _from, address _to, uint _value) private {
    require(storageContract.valid(_from), "401");
    _balances[_from] = _balances[_from] - _value;
    _balances[_to] = _balances[_to] + _value;
    if (_to == address(0)) {
      totalSupply = totalSupply - _value;
    }
    emit Transfer(_from, _to, _value);
  }

  function _approve(address _owner, address _spender, uint _value) private {
    require(_spender != address(0));
    require(_owner != address(0));

    _allowed[_owner][_spender] = _value;
    emit Approval(_owner, _spender, _value);
  }

  function _mint(address _owner, uint _amount) private {
    _balances[_owner] = _balances[_owner] + _amount;
    totalSupply = totalSupply + _amount;
    emit Transfer(address(0), _owner, _amount);
  }

}