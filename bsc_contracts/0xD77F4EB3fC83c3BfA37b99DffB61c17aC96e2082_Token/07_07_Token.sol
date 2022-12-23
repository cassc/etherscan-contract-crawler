// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract Token is ERC20PresetFixedSupply {
  uint8 internal immutable _decimals;

  constructor(
    string memory name,
    string memory symbol,
    uint256 totalSupply,
    uint8 dec
  ) ERC20PresetFixedSupply(name, symbol, totalSupply, msg.sender) {
    _decimals = dec;
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }
}