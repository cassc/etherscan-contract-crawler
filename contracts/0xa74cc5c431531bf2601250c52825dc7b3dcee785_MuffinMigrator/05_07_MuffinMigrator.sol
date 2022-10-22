// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IManagerMinimal} from "./interfaces/muffin/IManagerMinimal.sol";
import {INonfungiblePositionManagerMinimal} from "./interfaces/uniswap/INonfungiblePositionManagerMinimal.sol";

contract MuffinMigrator is ReentrancyGuard {
    address public immutable weth;
    IManagerMinimal public immutable muffinManager;
    INonfungiblePositionManagerMinimal public immutable uniV3PositionManager;

    struct PermitUniV3Params {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct MintParams {
        bool needCreatePool;
        bool needAddTier;
        uint128 sqrtPrice;
        uint24 sqrtGamma;
        uint8 tierId;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
    }

    constructor(address muffinManager_, address uniV3PositionManager_) {
        muffinManager = IManagerMinimal(muffinManager_);
        uniV3PositionManager = INonfungiblePositionManagerMinimal(uniV3PositionManager_);
        weth = muffinManager.WETH9();
    }

    // only receive from WETH contract for refund
    receive() external payable {
        require(weth == msg.sender, "WETH only");
    }

    /// @notice Migrate Uniswap V3 position to Muffin position
    /// @dev Only the tokens withdrew during the decrease liquidity will be collected,
    /// i.e. fees are remaining inside the Uniswap's position.
    /// @param permitParams subset of paramenters for Uniswap's `NonfungiblePositionManager.permit`
    /// @param removeParams paramenters for Uniswap's `INonfungiblePositionManager.decreaseLiquidity`
    /// @param mintParams needCreatePool indicate the need of creating new Muffin's pool,
    /// the amount of both burnt tokens need to exceed certain amount for creation.
    /// needAddTier indicate the need of adding new fee tier to the Muffin's pool,
    /// the amount of both burnt tokens need to exceed certain amount for addition.
    /// sqrtPrice the sqrt price value for creating new Muffin's pool.
    /// sqrtGamma the sqrt gamma value for adding new fee tier.
    /// ...others are subset of paramenters for Muffin's `Manager.mint`
    /// @param refundAsETH `true` for refund WETH as ETH
    function migrateFromUniV3WithPermit(
        PermitUniV3Params calldata permitParams,
        INonfungiblePositionManagerMinimal.DecreaseLiquidityParams calldata removeParams,
        MintParams calldata mintParams,
        bool refundAsETH
    ) external nonReentrant {
        // permit this contract to access the Uniswap V3 position
        // also act as token owner validation
        uniV3PositionManager.permit(
            address(this),
            removeParams.tokenId,
            permitParams.deadline,
            permitParams.v,
            permitParams.r,
            permitParams.s
        );

        // get uniswap position info
        (address token0, address token1) = _getUniV3PositionTokenPair(removeParams.tokenId);

        // record the current balance of tokens
        uint256 balance0 = ERC20(token0).balanceOf(address(this));
        uint256 balance1 = ERC20(token1).balanceOf(address(this));

        // remove and collect Uniswap V3 position
        (uint256 amount0, uint256 amount1) = _removeAndCollectUniV3Position(removeParams);

        // allow muffin manager to use the tokens
        _approveTokenToMuffinManager(token0, amount0);
        _approveTokenToMuffinManager(token1, amount1);

        // mint muffin position
        _mintPosition(token0, token1, mintParams);

        // calculate the remaining tokens, need underflow to check if over-used
        balance0 = ERC20(token0).balanceOf(address(this)) - balance0;
        balance1 = ERC20(token1).balanceOf(address(this)) - balance1;

        // refund remaining tokens to recipient's wallet
        _refund(token0, mintParams.recipient, balance0, refundAsETH);
        _refund(token1, mintParams.recipient, balance1, refundAsETH);
    }

    function _getUniV3PositionTokenPair(uint256 tokenId)
        internal
        view
        returns (address token0, address token1)
    {
        (
            ,
            ,
            token0,
            token1,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
        ) = uniV3PositionManager.positions(tokenId);
    }

    function _removeAndCollectUniV3Position(
        INonfungiblePositionManagerMinimal.DecreaseLiquidityParams calldata removeParams
    ) internal returns (
        uint256 amount0,
        uint256 amount1
    ) {
        (
            uint256 burntAmount0,
            uint256 burntAmount1
        ) = uniV3PositionManager.decreaseLiquidity(removeParams);

        // collect only the burnt amount, i.e. the fee will be left in the position
        (amount0, amount1) = uniV3PositionManager.collect(
            INonfungiblePositionManagerMinimal.CollectParams({
                tokenId: removeParams.tokenId,
                recipient: address(this),
                // Uniswap assumed all token balances < 2^128
                // See https://github.com/Uniswap/v3-core/blob/main/bug-bounty.md#assumptions
                amount0Max: uint128(burntAmount0),
                amount1Max: uint128(burntAmount1)
            })
        );
    }

    /// @notice Safe approve ERC20 token.
    /// @dev Modified from solmate's `SafeTransferLib`.
    /// It returns the success flag instead of revert it immediately.
    function _trySafeApprove(ERC20 token, address to, uint256 amount) internal returns (bool success) {
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }
    }

    function _approveTokenToMuffinManager(address token, uint256 amount) internal {
        uint256 allowance = ERC20(token).allowance(address(this), address(muffinManager));
        if (allowance >= amount) return;

        // revoke allowance before setting a new one, revert if unable to reset
        if (allowance != 0) SafeTransferLib.safeApprove(ERC20(token), address(muffinManager), 0);

        // first try allow max amount
        if (!_trySafeApprove(ERC20(token), address(muffinManager), type(uint256).max)) {
            // if failed, allow only exact amount
            SafeTransferLib.safeApprove(ERC20(token), address(muffinManager), amount);
        }
    }

    function _mintPosition(address token0, address token1, MintParams calldata mintParams) internal {
        if (mintParams.needCreatePool) {
            muffinManager.createPool(token0, token1, mintParams.sqrtGamma, mintParams.sqrtPrice, false);
        } else if (mintParams.needAddTier) {
            muffinManager.addTier(token0, token1, mintParams.sqrtGamma, false, mintParams.tierId);
        }

        muffinManager.mint(
            IManagerMinimal.MintParams({
                token0: token0,
                token1: token1,
                tierId: mintParams.tierId,
                tickLower: mintParams.tickLower,
                tickUpper: mintParams.tickUpper,
                amount0Desired: mintParams.amount0Desired,
                amount1Desired: mintParams.amount1Desired,
                amount0Min: mintParams.amount0Min,
                amount1Min: mintParams.amount1Min,
                recipient: mintParams.recipient,
                useAccount: false
            })
        );
    }

    function _refund(address token, address to, uint256 amount, bool refundAsETH) internal {
        if (amount == 0) return;
        if (token == weth && refundAsETH) {
            WETH(payable(weth)).withdraw(amount);
            SafeTransferLib.safeTransferETH(to, amount);
            return;
        }
        SafeTransferLib.safeTransfer(ERC20(token), to, amount);
    }
}