// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function coins(uint256 index) external view returns(IERC20);
    function getA() external view returns (uint256);
    function getTokenIndex(address token) external view returns (uint8);

    function getVirtualPrice() external view returns (uint256);

    function calculateSwap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx) external view returns (uint256 dy);
    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory);
    function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256);
    function calculateWithdrawOneToken(uint256 tokenAmount, uint8 tokenIndex) external view returns (uint256 amount);

    function swap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline) external returns (uint256);
    function addLiquidity(uint256[] memory amounts, uint256 minToMint, uint256 deadline) external returns (uint256);
    function removeLiquidity(uint256 amount, uint256[] calldata minAmounts, uint256 deadline) external returns (uint256[] memory);
    function removeLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex, uint256 minAmount, uint256 deadline) external returns (uint256);
    function removeLiquidityImbalance(uint256[] calldata amounts, uint256 maxBurnAmount, uint256 deadline) external returns (uint256);

    function applySwapFee(uint256 newSwapFee) external;
    function applyAdminFee(uint256 newAdminFee) external;
    function getAdminBalance(uint256 index) external view returns (uint256);
    function withdrawAdminFee(address receiver) external;
    function rampA(uint256 _futureA, uint256 _futureTime) external;
    function stopRampA() external;
}