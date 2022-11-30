// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "./LibAsset.sol";
import "./LibSubAccount.sol";
import "./LibMath.sol";
import "../interfaces/IMuxRebalancerCallback.sol";
import "../core/Account.sol";
import "../core/Storage.sol";

/**
 * Low frequency operations of Liquidity
 */
library LibLiquidity {
    using LibAsset for Asset;
    using LibMath for uint256;
    using LibSubAccount for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Redeem mux token into original tokens.
     *
     *         Only strict stable coins and un-stable coins are supported.
     */
    function redeemMuxToken(
        LiquidityPoolStorage storage _storage,
        address trader,
        uint8 tokenId,
        uint96 muxTokenAmount // NOTE: OrderBook SHOULD transfer muxTokenAmount to LiquidityPool
    ) external {
        require(trader != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(_storage, tokenId), "LST"); // the asset is not LiSTed
        require(muxTokenAmount != 0, "A=0"); // Amount Is Zero
        Asset storage token = _storage.assets[tokenId];
        require(token.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        if (token.isStable()) {
            require(token.isStrictStable(), "STR"); // only STRict stable coins and un-stable coins are supported
        }
        require(token.spotLiquidity >= muxTokenAmount, "LIQ"); // insufficient LIQuidity
        uint256 rawAmount = token.toRaw(muxTokenAmount);
        token.spotLiquidity -= muxTokenAmount;
        token.transferOut(trader, rawAmount, _storage.weth, _storage.nativeUnwrapper);
    }

    /**
     * @dev  Rebalance pool liquidity. Swap token 0 for token 1.
     *
     *       rebalancer must implement IMuxRebalancerCallback.
     * @return rawAmount1 received amount of token 1.
     */
    function rebalance(
        LiquidityPoolStorage storage _storage,
        address rebalancer,
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0,
        uint96 maxRawAmount1,
        bytes32 userData,
        uint96 price0,
        uint96 price1
    ) external returns (uint96) {
        require(rebalancer != address(0), "R=0"); // Rebalancer address is zero
        require(_hasAsset(_storage, tokenId0), "LST"); // the asset is not LiSTed
        require(_hasAsset(_storage, tokenId1), "LST"); // the asset is not LiSTed
        require(rawAmount0 != 0, "A=0"); // Amount Is Zero
        Asset storage token0 = _storage.assets[tokenId0];
        Asset storage token1 = _storage.assets[tokenId1];
        price0 = LibReferenceOracle.checkPrice(_storage, token0, price0);
        price1 = LibReferenceOracle.checkPrice(_storage, token1, price1);
        require(token0.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(token1.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        // send token 0. get amount 1
        uint256 expectedRawAmount1;
        {
            uint96 amount0 = token0.toWad(rawAmount0);
            require(token0.spotLiquidity >= amount0, "LIQ"); // insufficient LIQuidity
            token0.spotLiquidity -= amount0;

            uint96 expectedAmount1 = ((uint256(amount0) * uint256(price0)) / uint256(price1)).safeUint96();
            expectedRawAmount1 = token1.toRaw(expectedAmount1);
        }
        require(expectedRawAmount1 <= maxRawAmount1, "LMT"); // LiMiTed by limitPrice
        // swap. check amount 1
        uint96 rawAmount1;
        {
            IERC20Upgradeable(token0.tokenAddress).safeTransfer(rebalancer, rawAmount0);
            uint256 rawAmount1Old = IERC20Upgradeable(token1.tokenAddress).balanceOf(address(this));
            IMuxRebalancerCallback(rebalancer).muxRebalanceCallback(
                token0.tokenAddress,
                token1.tokenAddress,
                rawAmount0,
                expectedRawAmount1,
                userData
            );
            uint256 rawAmount1New = IERC20Upgradeable(token1.tokenAddress).balanceOf(address(this));
            require(rawAmount1Old <= rawAmount1New, "T1A"); // Token 1 Amount mismatched
            rawAmount1 = (rawAmount1New - rawAmount1Old).safeUint96();
        }
        require(rawAmount1 >= expectedRawAmount1, "T1A"); // Token 1 Amount mismatched
        token1.spotLiquidity += token1.toWad(rawAmount1);
        return rawAmount1;
    }

    /**
     * @dev Anyone can withdraw collectedFee into Vault.
     * @return collectedFee decimals = 18.
     */
    function withdrawCollectedFee(LiquidityPoolStorage storage _storage, uint8 assetId) external returns (uint96) {
        require(_storage.vault != address(0), "VLT"); // bad VauLT
        require(_hasAsset(_storage, assetId), "LST"); // the asset is not LiSTed
        Asset storage asset = _storage.assets[assetId];
        uint96 collectedFee = asset.collectedFee;
        require(collectedFee <= asset.spotLiquidity, "LIQ"); // insufficient LIQuidity
        asset.collectedFee = 0;
        asset.spotLiquidity -= collectedFee;
        uint256 rawAmount = asset.toRaw(collectedFee);
        IERC20Upgradeable(asset.tokenAddress).safeTransfer(_storage.vault, rawAmount);
        return collectedFee;
    }

    function _hasAsset(LiquidityPoolStorage storage _storage, uint8 assetId) internal view returns (bool) {
        return assetId < _storage.assets.length;
    }
}