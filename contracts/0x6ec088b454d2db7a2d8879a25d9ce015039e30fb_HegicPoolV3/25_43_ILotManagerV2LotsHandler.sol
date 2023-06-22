// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

interface ILotManagerV2LotsHandler {
  event ETHLotBought(uint256 amount);
  event WBTCLotBought(uint256 amount);
  event ETHLotSold(uint256 amount);
  event WBTCLotSold(uint256 amount);
  event LotsRebalanced(uint256 _ethLots, uint256 _wbtcLots);
  
  function balanceOfUnderlying() external view returns (uint256 _underlyingBalance);
  function balanceOfLots() external view returns (uint256 _ethLots, uint256 _wbtcLots);
  function profitOfLots() external view returns (uint256 _ethProfit, uint256 _wbtcProfit);
  function buyLots(uint256 _ethLots, uint256 _wbtcLots) external returns (bool);
  function sellLots(uint256 _ethLots, uint256 _wbtcLots) external returns (bool);
  function rebalanceLots(uint256 _ethLots, uint256 _wbtcLots) external returns (bool);
}