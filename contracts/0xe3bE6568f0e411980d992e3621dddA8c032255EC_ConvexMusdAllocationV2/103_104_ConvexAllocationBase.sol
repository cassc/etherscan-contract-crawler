// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath} from "contracts/libraries/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";
import {ImmutableAssetAllocation} from "contracts/tvl/Imports.sol";
import {IRewardPool} from "./interfaces/IBaseRewardPool.sol";

interface ICurvePool {
    function balances(uint256 coin) external view returns (uint256);
}

/**
 * @title Periphery Contract for the Curve 3pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of a Curve LP token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract ConvexAllocationBase {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's LP token balance.
     * @param stableSwap the liquidity pool comprised of multiple underlyers
     * @param rewardContract the staking contract for the LP tokens
     * @param lpToken the LP token representing the share of the pool
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        address stableSwap,
        address rewardContract,
        address lpToken,
        uint256 coin
    ) public view returns (uint256 balance) {
        require(stableSwap != address(0), "INVALID_STABLESWAP");
        require(rewardContract != address(0), "INVALID_GAUGE");
        require(lpToken != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(stableSwap, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, rewardContract, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(address stableSwap, uint256 coin)
        public
        view
        returns (uint256)
    {
        require(stableSwap != address(0), "INVALID_STABLESWAP");
        return ICurvePool(stableSwap).balances(coin);
    }

    function getLpTokenShare(
        address account,
        address rewardContract,
        address lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(rewardContract != address(0), "INVALID_GAUGE");
        require(lpToken != address(0), "INVALID_LP_TOKEN");

        totalSupply = IERC20(lpToken).totalSupply();
        // Need to be careful to not include the balance of `account`,
        // since that is included in the Curve allocation.
        balance = IRewardPool(rewardContract).balanceOf(account);
    }
}