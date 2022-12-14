// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

struct Split {
  address payee;
  uint32 percentShareOfRevenue;
  uint32 percentRevenueInProjectToken;
}

struct DerivedSplitInfo {
  uint32[] instanceTokenSplits;
  uint32 instanceTokenSplitsTotal;
  uint32[] revenueTokenSplits;
  uint32 revenueTokenSplitsTotal;
}

interface IRevenueManager {
  event RevenuePayout(address token, address recipient, uint256 amount);
  event EthReceived(address sender, uint256 amount);

  function distribute() external;

  function withdrawOtherERC20(
    address erc20ContractAddr,
    uint256 amount,
    address transferTo
  ) external;
}