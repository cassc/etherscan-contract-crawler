// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/GNSPS-solidity-bytes-utils/BytesLib.sol";
import "../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../external/interfaces/balancer/IBalancerVault.sol";
import "../interfaces/ISwapData.sol";

/// @title Contains logic facilitating swapping using Balancer
abstract contract SwapHelperBalancer {
    using BytesLib for bytes;
    using SafeERC20 for IERC20;

    /// @dev The length of the bytes encoded swap size
    uint256 private constant NUM_SWAPS_SIZE = 1;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;

    /// @dev The length of the bytes encoded pool ID
    uint256 private constant POOLID_SIZE = 32;

    /// @dev The length of the indexes size
    uint256 private constant INDEXES_SIZE = 2;

    /// @dev The length of the maximum swap size
    uint256 private constant MAX_SWAPS = 4;

    /// @dev The length of the bytes encoded poolID and indexes size
    uint256 private constant SWAPS_SIZE = POOLID_SIZE + INDEXES_SIZE;

    /// @notice Balancer master vault
    IBalancerVault private immutable vault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    /**
     * @notice Approve reward token and swap the `amount` to a strategy underlying asset
     * @param from Token to swap from
     * @param to Token to swap to
     * @param amount Amount of tokens to swap
     * @param swapData Swap details showing the path of the swap
     * @return result Amount of underlying (`to`) tokens recieved
     */
    function _approveAndSwapBalancer(
        IERC20 from,
        IERC20 to,
        uint256 amount,
        SwapData calldata swapData
    ) internal virtual returns (uint256) {
        // if there is nothing to swap, return
        if (amount == 0) return 0;

        // if amount is not uint256 max approve vault to spend tokens
        // otherwise rewards were already sent to the vault
        bool fromInternalBalance;
        if (amount < type(uint256).max) {
            from.safeApprove(address(vault), amount);
        } else {
            fromInternalBalance = true;
        }

        (BatchSwapStep[] memory swaps, IAsset[] memory assets) = _getBatchSwapsAndAssets(amount, swapData.path[1:]);

        FundManagement memory funds = FundManagement({
            sender: address(this),
            fromInternalBalance: fromInternalBalance,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        uint256 result = _swapBal(from, to, swaps, assets, funds, swapData.slippage);

        if (from.allowance(address(this), address(vault)) > 0) {
            from.safeApprove(address(vault), 0);
        }
        return result;
    }

    /**
     * @notice Swaps tokens using Balancer
     * @param from Token to swap from
     * @param to Token to swap to
     * @param swaps pools with asset indexes
     * @param slippage assets used in the swap
     * @return result Amount of underlying (`to`) tokens recieved
     */
    function _swapBal(
        IERC20 from,
        IERC20 to,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        uint256 slippage
    ) internal virtual returns (uint256) {
        // we need to verify that the first and last index in and index out in the swaps is the 'from' and 'to' address respectively
        require(
            address(assets[swaps[0].assetInIndex]) == address(from),
            "SwapHelperBalancer:_swapBal:: from token incorrect."
        );
        require(
            address(assets[swaps[swaps.length - 1].assetOutIndex]) == address(to),
            "SwapHelperBalancer:_swapBal:: to token incorrect."
        );

        int256[] memory limits = new int256[](assets.length);
        limits[0] = int256(swaps[0].amount);

        uint256 toBalance = to.balanceOf(address(this));
        vault.batchSwap(SwapKind.GIVEN_IN, swaps, assets, funds, limits, type(uint256).max);
        uint256 toBalanceAfter = to.balanceOf(address(this)) - toBalance;
        require(toBalanceAfter >= slippage, "SwapHelperBalancer:_swapBal:: Insufficient Amount Swapped");

        return toBalanceAfter;
    }

    /**
     * @notice Convert bytes path into swaps and assets for batchSwap
     * @param amount Token amount to swap (for first swap only)
     * @param pathBytes bytes encoded swaps and assets
     */
    function _getBatchSwapsAndAssets(uint256 amount, bytes calldata pathBytes)
        internal
        pure
        returns (BatchSwapStep[] memory swaps, IAsset[] memory assets)
    {
        // assert swap data
        uint256 numSwaps = pathBytes.toUint8(0);
        require(numSwaps > 0 && numSwaps <= MAX_SWAPS);

        // assert asset data
        uint256 startAssets = NUM_SWAPS_SIZE + (numSwaps * SWAPS_SIZE);
        uint256 assetsPathSize = pathBytes.length - startAssets;
        uint256 numAssets = assetsPathSize / ADDR_SIZE;
        require(assetsPathSize % ADDR_SIZE == 0 && numAssets <= (numSwaps + 1));

        // Get swaps
        swaps = new BatchSwapStep[](numSwaps);
        swaps[0].amount = amount;
        for (uint256 i = 0; i < numSwaps; i++) {
            swaps[i].poolId = pathBytes.toBytes32(NUM_SWAPS_SIZE + (i * SWAPS_SIZE));
            swaps[i].assetInIndex = pathBytes.toUint8(NUM_SWAPS_SIZE + (i * SWAPS_SIZE) + POOLID_SIZE);
            swaps[i].assetOutIndex = pathBytes.toUint8(NUM_SWAPS_SIZE + (i * SWAPS_SIZE) + POOLID_SIZE + 1);
        }

        // Get assets
        assets = new IAsset[](numAssets);
        for (uint256 i = 0; i < numAssets; i++) {
            assets[i] = IAsset(pathBytes.toAddress(startAssets + (i * ADDR_SIZE)));
        }

        return (swaps, assets);
    }
}