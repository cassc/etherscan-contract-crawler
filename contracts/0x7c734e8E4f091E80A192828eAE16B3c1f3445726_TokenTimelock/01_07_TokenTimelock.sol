// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/TokenTimelockUpgradeable.sol";

contract TokenTimelock is TokenTimelockUpgradeable {
  function initialize(
    IERC20Upgradeable token_,
    address beneficiary_,
    uint256 releaseTime_
  ) external initializer {
    __TokenTimelock_init(token_, beneficiary_, releaseTime_);
  }
}