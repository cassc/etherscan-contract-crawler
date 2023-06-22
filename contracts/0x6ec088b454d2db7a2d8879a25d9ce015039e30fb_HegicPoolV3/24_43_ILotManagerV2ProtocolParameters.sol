// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../../../interfaces/zTreasury/V2/IZTreasuryV2.sol';
import '../../../interfaces/HegicPool/IHegicPoolV2.sol';
import '../../../interfaces/IHegicStaking.sol';

interface ILotManagerV2ProtocolParameters {
  event PerformanceFeeSet(uint256 _performanceFee);
  event ZTreasurySet(address _zTreasury);
  event PoolSet(address _pool, address _token);
  event WETHSet(address _weth);
  event WBTCSet(address _wbtc);
  event HegicStakingSet(address _hegicStakingETH, address _hegicStakingWBTc);

  function uniswapV2() external returns (address);
  function LOT_PRICE() external returns (uint256);
  function FEE_PRECISION() external returns (uint256);
  function MAX_PERFORMANCE_FEE() external returns (uint256);
  function lotPrice() external view returns (uint256); // deprecated for LOT_PRICE
  function getPool() external view returns (address); // deprecated for pool

  function performanceFee() external returns (uint256);
  function zTreasury() external returns (IZTreasuryV2);

  function weth() external returns (address);
  function wbtc() external returns (address);
  function hegicStakingETH() external returns (IHegicStaking);
  function hegicStakingWBTC() external returns (IHegicStaking);

  function pool() external returns (IHegicPoolV2);
  function token() external returns (IERC20);

  function setPerformanceFee(uint256 _performanceFee) external;
  function setZTreasury(address _zTreasury) external;
  function setPool(address _pool) external;
  function setWETH(address _weth) external;
  function setWBTC(address _wbtc) external;
  function setHegicStaking(address _hegicStakingETH, address _hetgicStakingWBTC) external;
}