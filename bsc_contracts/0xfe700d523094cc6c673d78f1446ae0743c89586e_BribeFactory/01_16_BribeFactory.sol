// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./02_16_Bribe.sol";
import "./03_16_IBribeFactory.sol";

contract BribeFactory is IBribeFactory {
  address public lastGauge;

  event BribeCreated(address value);

  function createBribe(address[] memory _allowedRewardTokens) external override returns (address) {
    address _lastGauge = address(new Bribe(
        msg.sender,
        _allowedRewardTokens
      ));
    lastGauge = _lastGauge;
    emit BribeCreated(_lastGauge);
    return _lastGauge;
  }
}