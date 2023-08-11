// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for staking feature for Curve adapters
 * @author Opty.fi
 * @notice Interface of CurveDeposit and CurveSwap adapters for staking functionality
 * @dev Abstraction layer to Curve.fi adapters
 * It is used as a layer for adding any new staking functions being used in Curve adapters.
 * Conventions used:
 *  - lpToken: liquidity pool token
 */
interface IAdapterStakingCurve {
    /**
     * @notice Returns the balance in underlying for staked liquidityPoolToken balance of holder
     * @dev It should only be implemented in Curve adapters
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address for the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address where the vault has deposited and which is associated
     * to a staking pool where to stake all lpTokens
     * @return Returns the equivalent amount of underlying tokens to the staked amount of liquidityPoolToken
     */
    function getAllAmountInTokenStakeWrite(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) external returns (uint256);

    /**
     * @notice Returns the equivalent amount in underlying token if the given amount of lpToken is unstaked and redeemed
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to get amount to redeem
     * @param _redeemAmount Amount of lpToken to redeem for staking
     * @return _amount Returns the lpToken amount that can be redeemed
     */
    function calculateRedeemableLPTokenAmountStakeWrite(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) external returns (uint256);

    /**
     * @notice Checks whether the given amount of underlying token can be received for full balance of staked lpToken
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address where to check the redeem amt is enough to stake
     * @param _redeemAmount amount specified underlying token that can be received for full balance of staking lpToken
     * @return Returns a boolean true if _redeemAmount is enough to stake and false if not enough
     */
    function isRedeemableAmountSufficientStakeWrite(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) external returns (bool);

    /**
     * @notice Returns the amount of accrued reward tokens
     * @param _vault Vault contract address
     * @param _liquidityPool Liquidity pool's contract address from where to claim reward tokens
     * @param _underlyingToken Underlying token's contract address for which to claim reward tokens
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getUnclaimedRewardTokenAmountWrite(
        address payable _vault,
        address _liquidityPool,
        address _underlyingToken
    ) external returns (uint256);
}