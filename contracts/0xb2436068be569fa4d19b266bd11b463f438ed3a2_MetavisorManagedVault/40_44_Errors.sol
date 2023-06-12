// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

abstract contract Errors {
    error NotPool(address sender);
    error NotWETH(address sender);

    error InvalidNumerator(uint256 numerator);
    error AlreadyDeployed();
    error ZeroAddress();
    error InvalidPool();
    error AlreadySet();

    error ExternalTransferFailed();
    error NotAllowedToRescale(address sender);
    error TwapCheckFailed(uint32 twapInterval, uint256 priceThreshold);
    error InvalidWithdraw(uint256 shares);
    error InvalidPriceImpact(uint256 priceImpact);
    error InvalidLiquidityOperation();
    error InvalidCompound();
    error InvalidDeposit();
    error CanNotRescale();
    error NoLiquidity();

    error TicksOutOfRange(int24 tickLower, int24 tickUpper);
}