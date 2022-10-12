//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// ETH
contract BridgeIn {
  // Outstanding balance
  mapping(address => uint256) public balance;
  address public token;

  event Deposit(address indexed _from, uint256 _value);

  constructor(address _token) {
    token = _token;
  }

  function burn(uint256 _amount) public {
    console.log("hola");
    require(
      ERC20(token).transferFrom(msg.sender, address(this), _amount),
      "the transnfer failed"
    );
    balance[msg.sender] += _amount;
    emit Deposit(msg.sender, _amount);
  }

  function seeBalance(address _account) public view returns (uint256) {
    return balance[_account];
  }
}