// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IPinkLock {
  function lock(
    address owner,
    address token,
    bool isLpToken,
    uint256 amount,
    uint256 unlockDate
  ) external payable returns (uint256 id);

  function unlock(uint256 lockId) external;

  function editLock(
    uint256 lockId,
    uint256 newAmount,
    uint256 newUnlockDate
  ) external payable;
}