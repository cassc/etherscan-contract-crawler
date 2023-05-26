// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import '../libraries/DataStruct.sol';

interface IIncentivePool {
  event ClaimIncentive(address indexed user, uint256 claimedIncentive, uint256 userIncentiveIndex);

  event UpdateIncentivePool(address indexed user, uint256 accruedIncentive, uint256 incentiveIndex);

  event IncentivePoolEnded();

  event RewardPerSecondUpdated(uint256 newAmountPerSecond);

  event IncentiveEndTimestampUpdated(uint256 newEndTimestamp);

  function initializeIncentivePool(address lToken) external;

  function setAmountPerSecond(uint256 newAmountPerSecond) external;

  /**
   * @notice Admin can update incentive pool end timestamp
   */
  function setEndTimestamp(uint256 newEndTimestamp) external;

  function updateIncentivePool(address user) external;

  function beforeTokenTransfer(address from, address to) external;

  function claimIncentive() external;

  function withdrawResidue() external;
}