//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./StakingIncentives.sol";
import "../exchange41/SpotMarketAmm.sol";

/// @title StakingIncentives contract that works with V4.1 contracts.
/// @dev If any more changes are added to this contract, we should consider forking StakingIncentives completely
/// to decouple v4 and v4.1 contracts.
contract StakingIncentivesV41 is StakingIncentives {
    /// @notice Withdraw liquidity corresponding to the amount of LP tokens immediate caller can
    ///         withdraw from this incentives contract. The withdrawn tokens will be sent directly
    ///         to the immediate caller.
    /// @param minAssetAmount The minimum amount of asset tokens to redeem in exchange for the
    ///                        provided share of liquidity.
    ///                        happen regardless of the amount of asset in the result.
    /// @param minStableAmount The minimum amount of stable tokens to redeem in exchange for the
    ///                         provided share of liquidity.
    /// @param useEth Whether to pay out liquidity using raw ETH for whichever token is WETH.
    function withdrawLiquidity_v2(
        int256 minAssetAmount,
        int256 minStableAmount,
        bool useEth
    ) external {
        uint256 amount = handleWithdraw();

        // slither-disable-next-line uninitialized-local
        SpotMarketAmm.RemoveLiquidityData memory removeLiquidityData;
        removeLiquidityData.minAssetAmount = minAssetAmount;
        removeLiquidityData.minStableAmount = minStableAmount;
        removeLiquidityData.receiver = msg.sender;
        removeLiquidityData.useEth = useEth;

        bytes memory data = abi.encode(removeLiquidityData);
        // We need to send the LP tokens (stakingToken) to the SpotMarketAmm because:
        // 1. It needs to return the withdrawn liquidity to the LP (immediate caller)
        // 2. Only the LP token contract's owner can burn the LP tokens and the amm is that owner.
        address amm = Ownable(address(stakingToken)).owner();
        require(stakingToken.transferAndCall(amm, amount, data), "transferAndCall failed");

        // Emit withdraw event to be consistent with the normal withdraw flow (withdrawing LP tokens without requesting
        // full liquidity withdrawal from the SpotMarketAmm).
        emit Withdraw(msg.sender, amount);
        emit WithdrawLiquidity(msg.sender, amount);
    }

    /// @notice Emitted when a user withdraws liquidity in one step through the StakingIncentivesV41 contract.
    /// @param account The account withdrawing tokens
    /// @param amount The amount being withdrawn
    event WithdrawLiquidity(address account, uint256 amount);
}