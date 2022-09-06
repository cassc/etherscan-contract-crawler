// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import { yVaultUpgradeable } from "../vendor/yearn/vaults/yVaultUpgradeable.sol";

contract BTCVault is yVaultUpgradeable {
  function initialize(
    address _token,
    address _controller,
    string memory _name,
    string memory _symbol
  ) public initializer {
    __yVault_init_unchained(_token, _controller, _name, _symbol);
  }
}