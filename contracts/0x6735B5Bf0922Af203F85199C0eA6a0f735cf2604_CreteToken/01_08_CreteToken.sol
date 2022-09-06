//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol';

contract CreteToken is ERC20CappedUpgradeable {
  address public constant recipient1 = 0x236bE8c3C76904a0432bc2A93b80838E29f86738;
  address public constant recipient2 = 0xF7D2c7C5c7f38A9f64f6940fAf8FbA97eD187Cc4;

  uint256 public constant recipient1Amount = 42_000_000e18;
  uint256 public constant recipient2Amount = 58_000_000e18;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() external initializer {
    __ERC20Capped_init(100_000_000e18);
    __ERC20_init('Crete Token', 'CRT');
    _mint(recipient1, recipient1Amount);
    _mint(recipient2, recipient2Amount);
  }
}