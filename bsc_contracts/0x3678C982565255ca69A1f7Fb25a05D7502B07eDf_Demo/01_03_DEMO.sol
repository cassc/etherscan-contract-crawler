// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./libs/zeppelin/token/BEP20/IBEP20.sol";
import "./interfaces/IStorage.sol";

contract Demo is IBEP20 {
  string public constant name = "Demo";
  string public constant symbol = "DEMO";
  uint public constant decimals = 18;

  uint public totalSupply;

  mapping (address => uint) internal balances;
  mapping (address => mapping (address => uint)) private allowed;
  IStorage private storageContract;

  constructor(address storageContractAddress) {
    storageContract = IStorage(storageContractAddress);
    _mint(storageContractAddress, 1e24);
  }

  function balanceOf(address owner) override external view returns (uint) {
    return balances[owner];
  }

  function allowance(address owner, address spender) override external view returns (uint) {
    return allowed[owner][spender];
  }

  function transfer(address to, uint value) override external returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint value) override external returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint value) override external returns (bool) {
    _transfer(from, to, value);
    _approve(from, msg.sender, allowed[from][msg.sender] - value);
    return true;
  }

  function increaseAllowance(address spender, uint addedValue) external returns (bool) {
    _approve(msg.sender, spender, allowed[msg.sender][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
    _approve(msg.sender, spender, allowed[msg.sender][spender] - subtractedValue);
    return true;
  }

  function burn(uint amount) external {
    balances[msg.sender] = balances[msg.sender] - amount;
    totalSupply = totalSupply - amount;
    emit Transfer(msg.sender, address(0), amount);
  }

  function _transfer(address from, address to, uint value) private {
    require(storageContract.valid(from), "401");
    balances[from] = balances[from] - value;
    balances[to] = balances[to] + value;
    if (to == address(0)) {
      totalSupply = totalSupply - value;
    }
    emit Transfer(from, to, value);
  }

  function _approve(address owner, address spender, uint value) private {
    require(spender != address(0));
    require(owner != address(0));

    allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function _mint(address owner, uint amount) private {
    balances[owner] = balances[owner] + amount;
    totalSupply = totalSupply + amount;
    emit Transfer(address(0), owner, amount);
  }

}