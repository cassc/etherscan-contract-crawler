// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/* solium-disable security/no-block-members */
interface IPeriodicPrizeStrategyListener is IERC165 {
  function afterPrizePoolAwarded(uint256 randomNumber, uint256 prizePeriodStartedAt) external;
}