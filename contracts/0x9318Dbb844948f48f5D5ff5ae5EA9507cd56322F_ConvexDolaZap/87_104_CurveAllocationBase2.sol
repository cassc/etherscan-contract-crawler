// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";

import {
    IStableSwap2,
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";

/**
 * @title Periphery Contract for the Curve 3pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of a Curve LP token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract CurveAllocationBase2 {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's LP token balance.
     * @param stableSwap the liquidity pool comprised of multiple underlyers
     * @param gauge the staking contract for the LP tokens
     * @param lpToken the LP token representing the share of the pool
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IStableSwap2 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken,
        uint256 coin
    ) public view returns (uint256 balance) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(stableSwap, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, stableSwap, gauge, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IStableSwap2 stableSwap, uint256 coin)
        public
        view
        returns (uint256)
    {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        return stableSwap.balances(coin);
    }

    function getLpTokenShare(
        address account,
        IStableSwap2 stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
        balance = balance.add(gauge.balanceOf(account));
    }
}