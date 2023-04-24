// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { YieldSlice } from  "./YieldSlice.sol";
import { NPVToken } from "../tokens/NPVToken.sol";
import { ILiquidityPool } from "../interfaces/ILiquidityPool.sol";

/// @title Swap future yield for upfront tokens.
contract NPVSwap {
    using SafeERC20 for IERC20;

    NPVToken public immutable npvToken;
    YieldSlice public immutable slice;
    ILiquidityPool public immutable pool;

    /// @notice Create an NPVSwap.
    /// @param slice_ Yield slice contract that will use to slice and swap yield.
    /// @param pool_ Liquidity pool to trade NPV for real tokens.
    constructor(address slice_, address pool_) {
        address npvToken_ = address(YieldSlice(slice_).npvToken());
        require(npvToken_ == ILiquidityPool(pool_).token0() ||
                npvToken_ == ILiquidityPool(pool_).token1(), "NS: wrong token");

        npvToken = NPVToken(npvToken_);
        slice = YieldSlice(slice_);
        pool = ILiquidityPool(pool_);
    }


    // --------------------------------------------------------- //
    // ---- Low level: Transacting in NPV tokens and slices ---- //
    // --------------------------------------------------------- //

    /// @notice Compute the amount of NPV that will be generated.
    /// @param tokens The number of yield generating tokens to be locked.
    /// @param yield The amount of yield to be commited into the slice.
    function previewLockForNPV(uint256 tokens, uint256 yield) public view returns (uint256) {
        (uint256 npv, uint256 fees) = slice.previewDebtSlice(tokens, yield);
        return npv - fees;
    }

    /// @notice Compute the result of a swap from yield to NPV tokens.
    /// @dev Not a view, and should not be used on-chain, due to underlying Uniswap v3 behavior.
    /// @param yieldIn The amount of yield tokens input.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    function previewSwapYieldForNPV(uint256 yieldIn, uint128 sqrtPriceLimitX96)
        public returns (uint256, uint256) {

        return pool.previewSwap(address(slice.yieldToken()),
                                uint128(yieldIn),
                                sqrtPriceLimitX96);
    }

    /// @notice Compute the result of a swap from yield to NPV tokens, with exact output.
    /// @dev Not a view, and should not be used, on-chain, due to underlying Uniswap v3 behavior.
    /// @param npvOut The amount of NPV tokens desired as output.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    function previewSwapYieldForNPVOut(uint256 npvOut, uint128 sqrtPriceLimitX96)
        public returns (uint256, uint256) {

        return pool.previewSwapOut(address(slice.yieldToken()),
                                   uint128(npvOut),
                                   sqrtPriceLimitX96);
    }

    /// @notice Compute the result of a swap from NPV tokens to yield.
    /// @dev Not a view, and should not be used on-chain, due to underlying Uniswap v3 behavior.
    /// @param npvIn The amount of NPV tokens input.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    function previewSwapNPVForYield(uint256 npvIn, uint128 sqrtPriceLimitX96)
        public returns (uint256, uint256) {

        return pool.previewSwap(address(npvToken),
                                uint128(npvIn),
                                sqrtPriceLimitX96);
    }

    /// @notice Compute the result of a swap from NPV tokens to yield, with exact output.
    /// @dev Not a view, and should not be used on-chain, due to underlying Uniswap v3 behavior.
    /// @param yieldOut The amount of yield tokens desired as output.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    function previewSwapNPVForYieldOut(uint256 yieldOut, uint128 sqrtPriceLimitX96)
        public returns (uint256, uint256) {

        return pool.previewSwapOut(address(npvToken),
                                   uint128(yieldOut),
                                   sqrtPriceLimitX96);
    }

    /// @notice Lock yield generating tokens to generate NPV tokens.
    /// @param owner Owner of the resulting yield slice.
    /// @param recipient Recipient of the NPV tokens.
    /// @param tokens The number of yield generating tokens to be locked.
    /// @param yield The amount of yield to be commited into the slice.
    /// @param memo Optional memo data to associate with the yield slice.
    function lockForNPV(address owner,
                        address recipient,
                        uint256 tokens,
                        uint256 yield,
                        bytes calldata memo) public returns (uint256) {

        IERC20(slice.generatorToken()).safeTransferFrom(msg.sender, address(this), tokens);
        slice.generatorToken().safeApprove(address(slice), 0);
        slice.generatorToken().safeApprove(address(slice), tokens);

        uint256 id = slice.debtSlice(owner, recipient, tokens, yield, memo);

        return id;
    }

    /// @notice Swap NPV tokens for a future yield in the form of a yield slice.
    /// @param recipient Recipient of the yield slice.
    /// @param npv Amount of NPV tokens to swap into the yield slice.
    /// @param memo Optional memo data to associate with the yield slice.
    function swapNPVForSlice(address recipient,
                             uint256 npv,
                             bytes calldata memo) public returns (uint256) {
        IERC20(slice.npvToken()).safeTransferFrom(msg.sender, address(this), npv);
        IERC20(slice.npvToken()).safeApprove(address(slice), 0); 
        IERC20(slice.npvToken()).safeApprove(address(slice), npv);

        uint256 id = slice.creditSlice(npv, recipient, memo);

        return id;
    }


    // --------------------------------------------------------------- //
    // ---- High level: Transacting in generator and yield tokens ---- //
    // --------------------------------------------------------------- //

    /// @notice Compute the result of a swap from locking yield into upfront yield.
    /// @dev Not a view, and should not be used on-chain, due to underlying Uniswap v3 behavior.
    /// @param tokens The number of yield generating tokens to be locked.
    /// @param yield The amount of yield to be commited into the slice.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    function previewLockForYield(uint256 tokens, uint256 yield, uint128 sqrtPriceLimitX96)
        public returns (uint256, uint256) {

        uint256 previewNPV = previewLockForNPV(tokens, yield);
        return pool.previewSwap(address(npvToken), uint128(previewNPV), sqrtPriceLimitX96);
    }

    /// @notice Compute the result of a swap of yield for future yield.
    /// @dev Not a view, and should not be used on-chain, due to underlying Uniswap v3 behavior.
    /// @param yieldIn The amount of yield tokens input.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    function previewSwapForSlice(uint256 yieldIn, uint128 sqrtPriceLimitX96) public returns (uint256, uint256) {
        (uint256 npv, uint256 priceX96) = pool.previewSwap(address(slice.yieldToken()),
                                                           uint128(yieldIn),
                                                           sqrtPriceLimitX96);
        uint256 fees = slice.creditFees(npv);
        return (npv - fees, priceX96);
    }

    /// @notice Lock yield generating tokens into a slice, and swap for yield tokens.
    /// @param owner Owner of the resulting debt yield slice.
    /// @param tokens The number of yield generating tokens to be locked.
    /// @param yield The amount of yield to be commited into the slice.
    /// @param amountOutMin Minimum amount of yield to output.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    /// @param memo Optional memo data to associate with the yield slice.
    function lockForYield(address owner,
                          uint256 tokens,
                          uint256 yield,
                          uint256 amountOutMin,
                          uint128 sqrtPriceLimitX96,
                          bytes calldata memo) public returns (uint256, uint256) {

        uint256 npv = previewLockForNPV(tokens, yield);
        uint256 id = lockForNPV(owner, address(this), tokens, yield, memo);

        IERC20(npvToken).safeApprove(address(pool), 0);
        IERC20(npvToken).safeApprove(address(pool), npv);
        uint256 out = pool.swap(owner,
                                address(npvToken),
                                uint128(npv),
                                uint128(amountOutMin),
                                sqrtPriceLimitX96);

        return (id, out);
    }

    /// @notice Swap upfront yield for a future yield slice.
    /// @param recipient Recipient of the future yield.
    /// @param yield Amount of upfront yield to swap for future yield.
    /// @param npvMin Minumum amount of NPV of yield to receive.
    /// @param sqrtPriceLimitX96 Price limit in sqrtX96 format.
    /// @param memo Optional memo data to associate with the yield slice.
    function swapForSlice(address recipient,
                          uint256 yield,
                          uint256 npvMin,
                          uint128 sqrtPriceLimitX96,
                          bytes calldata memo) public returns (uint256) {

        slice.yieldToken().safeTransferFrom(msg.sender, address(this), yield);
        slice.yieldToken().safeApprove(address(pool), 0);
        slice.yieldToken().safeApprove(address(pool), yield);

        uint256 out = pool.swap(address(this),
                                address(slice.yieldToken()),
                                uint128(yield),
                                uint128(npvMin),
                                sqrtPriceLimitX96);

        IERC20(slice.npvToken()).safeApprove(address(slice), 0);
        IERC20(slice.npvToken()).safeApprove(address(slice), out);
        uint256 id = slice.creditSlice(out, recipient, memo);

        return id;
    }

    // ----------------------------------------------------------------- //
    // ---- Repay with yield: Mint NPV with yield, and pay off debt ---- //
    // ----------------------------------------------------------------- //

    /// @notice Mint NPV tokens from yield at 1:1 rate, and pay off debt for a slice.
    /// @param id The debt slice ID.
    /// @param amount The amount of yield tokens to exchange for NPV tokens.
    function mintAndPayWithYield(uint256 id, uint256 amount) public {

        slice.yieldToken().safeTransferFrom(msg.sender, address(this), amount);
        slice.yieldToken().safeApprove(address(slice), 0);
        slice.yieldToken().safeApprove(address(slice), amount);
        slice.mintFromYield(address(this), amount);
        IERC20(slice.npvToken()).safeApprove(address(slice), 0);
        IERC20(slice.npvToken()).safeApprove(address(slice), amount);
        uint256 paid = slice.payDebt(id, amount);
        if (paid != amount) {
            IERC20(slice.npvToken()).safeTransfer(msg.sender, amount - paid);
        }
    }

}