// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
@dev An implementation of the ERC20 contract which has a fixed TotalSupply at creation time
*/
contract FixSupplyToken is ERC20 {
  // solhint-disable-next-line func-visibility
  constructor(
    string memory name,
    string memory symbol,
    address[] memory _initialHolders,
    uint256[] memory _initialBalances
  ) ERC20(name, symbol) {
    require(_initialHolders.length == _initialBalances.length, "arrays must have same lenght");
    for (uint256 i = 0; i < _initialHolders.length; i++) {
      _mint(_initialHolders[i], _initialBalances[i]);
    }
  }
}