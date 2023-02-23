// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract SpecialToken is ERC20 {

  address private minter;

  constructor(uint256 initialSupply, string memory name, string memory symbol, address _minter) ERC20(name, symbol) {
    _mint(_minter, initialSupply * (10 ** 18));
    minter = _minter;
  }
  function mintTokens(uint256 humanAmount) external {
      _mint(minter, humanAmount * (10 ** 18));
  }

}