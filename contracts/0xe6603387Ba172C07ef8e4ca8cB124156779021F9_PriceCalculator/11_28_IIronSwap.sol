// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "../../openzeppelin/IERC20.sol";

interface IIronSwap {
  /// EVENTS
  event AddLiquidity(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 tokenSupply
  );

  event TokenExchange(
    address indexed buyer,
    uint256 soldId,
    uint256 tokensSold,
    uint256 boughtId,
    uint256 tokensBought
  );

  event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256[] fees, uint256 tokenSupply);

  event RemoveLiquidityOne(address indexed provider, uint256 tokenIndex, uint256 tokenAmount, uint256 coinAmount);

  event RemoveLiquidityImbalance(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 tokenSupply
  );

  event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);

  event StopRampA(uint256 A, uint256 timestamp);

  event NewFee(uint256 fee, uint256 adminFee, uint256 withdrawFee);

  event CollectProtocolFee(address token, uint256 amount);

  event FeeControllerChanged(address newController);

  event FeeDistributorChanged(address newController);

  // pool data view functions
  function getLpToken() external view returns (IERC20 lpToken);

  function getA() external view returns (uint256);

  function getAPrecise() external view returns (uint256);

  function getToken(uint8 index) external view returns (IERC20);

  function getTokens() external view returns (IERC20[] memory);

  function getTokenIndex(address tokenAddress) external view returns (uint8);

  function getTokenBalance(uint8 index) external view returns (uint256);

  function getTokenBalances() external view returns (uint256[] memory);

  function getNumberOfTokens() external view returns (uint256);

  function getVirtualPrice() external view returns (uint256);

  function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256);

  function calculateSwap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view returns (uint256);

  function calculateRemoveLiquidity(address account, uint256 amount) external view returns (uint256[] memory);

  function calculateRemoveLiquidityOneToken(
    address account,
    uint256 tokenAmount,
    uint8 tokenIndex
  ) external view returns (uint256 availableTokenAmount);

  function getAdminBalances() external view returns (uint256[] memory adminBalances);

  function getAdminBalance(uint8 index) external view returns (uint256);

  function calculateCurrentWithdrawFee(address account) external view returns (uint256);

  // state modifying functions
  function swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy,
    uint256 deadline
  ) external returns (uint256);

  function addLiquidity(
    uint256[] calldata amounts,
    uint256 minToMint,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidity(
    uint256 amount,
    uint256[] calldata minAmounts,
    uint256 deadline
  ) external returns (uint256[] memory);

  function removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount,
    uint256 deadline
  ) external returns (uint256);

  function removeLiquidityImbalance(
    uint256[] calldata amounts,
    uint256 maxBurnAmount,
    uint256 deadline
  ) external returns (uint256);

  function updateUserWithdrawFee(address recipient, uint256 transferAmount) external;
}