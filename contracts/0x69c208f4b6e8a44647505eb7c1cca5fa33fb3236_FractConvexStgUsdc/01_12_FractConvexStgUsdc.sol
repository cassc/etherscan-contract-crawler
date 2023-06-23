// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import { ICurveSwap } from "../../interfaces/curve/ICurveSwap.sol";
import { IBooster } from "../../interfaces/convex/IBooster.sol";
import { IBaseRewardPool } from "../../interfaces/convex/IBaseRewardPool.sol";
import { ICvxMining } from "../../interfaces/convex/ICvxMining.sol";
import { IERC20 } from "../../../lib/openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../../../lib/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../base/FractBaseStrategy.sol";

contract FractConvexStgUsdc is FractBaseStrategy {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                        Constants and Immutables
    //////////////////////////////////////////////////////////////*/

    address constant CURVE_POOL = 0x3211C6cBeF1429da3D0d58494938299C92Ad5860;
    address constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address constant REWARD_POOL = 0x17E3Bc273cFcB972167059E55104DBCC8f8431bE;
    address constant LP_TOKEN = 0xdf55670e27bE5cDE7228dD0A6849181891c9ebA1;
    address constant CVX_MINING = 0x3c75BFe6FbfDa3A94E7E7E8c2216AFc684dE5343;

    /*///////////////////////////////////////////////////////////////
                            Base Operations
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Deposit into the strategy.
     * @param token token to deposit.
     * @param amount amount of tokens to deposit.
     */

    function deposit(IERC20 token, uint256 amount) external onlyOwner
    {
        _deposit(token, amount);
    }

    /**
     * @notice Withdraw from the strategy. 
     * @param token token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function withdraw(IERC20 token, uint256 amount) external onlyOwner 
    {
        _withdraw(token, amount);
    }

    /**
     * @notice Withdraw from the strategy to the owner. 
     * @param token token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function withdrawToOwner(IERC20 token, uint256 amount) external onlyOperator 
    {
        _withdrawToOwner(token, amount);
    }

    /**
     * @notice Swap rewards via the paraswap router.
     * @param token The token to swap.
     * @param amount The amount of tokens to swap. 
     * @param callData The callData to pass to the paraswap router. Generated offchain.
     */
    function swap(IERC20 token, uint256 amount, bytes memory callData) external payable onlyOperator 
    {
        //call internal swap
        _swap(token, amount, callData);
    }

    /*///////////////////////////////////////////////////////////////
                            Strategy Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Enter into a position with one or two tokens.
     * @param token0 token0 to enter a position with.
     * @param token1 token1 to enter a position with.
     * @param amount0 amount0 to enter a position with.
     * @param amount1 amount1 to enter a position with.
     * @param minAmount The minimum amount expected back after entering a position.
     */
    function enterPosition(
        IERC20 token0,
        IERC20 token1, 
        uint256 amount0,
        uint256 amount1, 
        uint256 minAmount) external onlyOwnerOrOperator
    {
        //approve
        token0.safeApprove(CURVE_POOL, amount0);
        token1.safeApprove(CURVE_POOL, amount1);
        //set array
        uint256[2] memory amounts = [amount0, amount1];
        //add liquidity
        ICurveSwap(CURVE_POOL).add_liquidity(amounts, minAmount);
        //lp token balance
        uint256 lpTokenBalance = IERC20(LP_TOKEN).balanceOf(address(this));
        //approve
        IERC20(LP_TOKEN).safeApprove(BOOSTER, lpTokenBalance);
        //deposit into convex
        IBooster(BOOSTER).depositAll(95, true);
        //revoke approvals
        token0.safeApprove(CURVE_POOL, 0);
        token1.safeApprove(CURVE_POOL, 0);
        IERC20(LP_TOKEN).safeApprove(BOOSTER, 0);

    }

    /**
     * @notice Exit a position
     * @param amount The amount to burn or exit a position with.
     * @param minAmount0 token0 minimum amount expected after exiting.
     * @param minAmount1 token1 minimum amount expected after exiting.
     */
    function exitPosition(
        uint256 amount, 
        uint256 minAmount0,
        uint256 minAmount1) external onlyOwnerOrOperator
    {
        //withdraw convex
        IBaseRewardPool(REWARD_POOL).withdrawAndUnwrap(amount, true);
        //approve
        IERC20(LP_TOKEN).safeApprove(CURVE_POOL, amount);
        //set array
        uint256[2] memory minAmounts = [minAmount0, minAmount1];
        //remove liquidity
        ICurveSwap(CURVE_POOL).remove_liquidity(amount, minAmounts);
        //revoke approve
        IERC20(LP_TOKEN).safeApprove(CURVE_POOL, 0);
    }

    /**
     * @notice Claim pending rewards.
     */
    function claimRewards() external onlyOperator 
    {
        IBaseRewardPool(REWARD_POOL).getReward(address(this), true);
    }

    /*///////////////////////////////////////////////////////////////
                                Getters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get pending rewards. 
     */
    function getPendingRewards() public view returns (uint256, uint256) 
    {
        uint256 crvRewards = IBaseRewardPool(REWARD_POOL).earned(address(this));
        uint256 cvxRewards = ICvxMining(CVX_MINING).ConvertCrvToCvx(crvRewards);

        return (crvRewards, cvxRewards);
    }


    /**
     * @notice Get LP token balance in reward pool. 
     */
    function getLpTokenBalance() public view returns (uint256)
    {
    
        return IBaseRewardPool(REWARD_POOL).balanceOf(address(this));

    }
}