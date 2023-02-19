// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKochiLock {
  struct SLPLockMetadata {
    address token0;
    address token1;
    uint256 amount0;
    uint256 amount1;
    address pair;
    uint256 liquidity;
    uint256 deadline;
  }

  // wip
  struct SLockMetadata {
    address token;
    uint256 amount;
    uint256 deadline;
  }

  struct SDEX {
    address factory;
    address router;
    address WETH;
  }

  event LockedLiquidity(address beneficiary, uint256 uid, address token0, address token1, uint256 amount0, uint256 amount1, address pair, uint256 liquidity, uint256 deadline);

  event LockedTokens(address beneficiary, uint256 uid, address token, uint256 amount, uint256 deadline);

  event UnlockedLiquidity(address beneficiary, address pair, uint256 uid, address token0, address token1, uint256 amount0, uint256 amount1, uint256 unlocked_liquidity, uint256 timestamp);

  event UnlockedTokens(address beneficiary, address token, uint256 uid, uint256 amount, uint256 timestamp);

  function lock(
    address token,
    uint256 amount,
    address beneficiary,
    uint256 deadline
  ) external;

  function lockETH(address beneficiary, uint256 deadline) external payable;

  function unlock(uint256 uid) external returns (uint256 tokens);

  function lpUnlock(uint256 uid) external returns (uint256 liquidity);

  function getUnlockedLiquidity(address beneficiary, address pair) external view returns (uint256 liquidity);

  function getUnlockedTokens(address beneficiary, address token) external view returns (uint256 tokens);

  function lpLockETH(
    address token,
    uint256 amount,
    uint256 lock_per_mille,
    address beneficiary,
    string memory dex,
    uint256 deadline
  ) external payable;

  function lpLock(
    address token0,
    address token1,
    uint256 amount0,
    uint256 amount1,
    uint256 lock_per_mille,
    address beneficiary,
    string memory dex,
    uint256 deadline
  ) external;

  function isDexSupported(string memory dex) external view returns (bool);
}