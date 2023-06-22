// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DinozERC20 is ERC20 {
  constructor() ERC20("Dinoz", "$XIT") {}

  function mint(uint256 _amount) external {
    _mint(msg.sender, _amount);
  }
}