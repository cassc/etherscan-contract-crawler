// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for staking feature for DeFi adapters
 * @author Opty.fi
 * @notice Interface of the DeFi protocol adapter for staking functionality
 * @dev Abstraction layer to different DeFi protocols like Harvest.finance, DForce etc.
 * It is used as a layer for adding any new staking functions being used in DeFi adapters.
 * Conventions used:
 *  - lpToken: liquidity pool token
 */
interface IAdapterStaking {
    /**
     * @notice Get batch of function calls for staking specified amount of lpToken held in a vault
     * @param _liquidityPool Liquidity pool's contract address where the vault has deposited and which is associated
     * to a staking pool where to stake some lpTokens
     * @param _stakeAmount Amount of lpToken (held in vault) to be staked
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getStakeSomeCodes(address _liquidityPool, uint256 _stakeAmount)
        external
        view
        returns (bytes[] memory _codes);

    /**
     * @notice Get batch of function calls for staking full balance of lpTokens held in a vault
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address where the vault has deposited and which is associated
     * to a staking pool where to stake all lpTokens
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getStakeAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) external view returns (bytes[] memory _codes);

    /**
     * @notice Get batch of function calls for unstaking specified amount of lpTokens held in a vault
     * @param _liquidityPool Liquidity pool's contract address where the vault has deposited and which is associated
     * to a staking pool where to unstake some lpTokens
     * @param _unstakeAmount Amount of lpToken (held in a vault) to be unstaked
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getUnstakeSomeCodes(address _liquidityPool, uint256 _unstakeAmount) external view returns (bytes[] memory);

    /**
     * @notice Get the batch of function calls for unstaking whole balance of lpTokens held in a vault
     * @param _vault Vault contract address
     * @param _liquidityPool Liquidity pool's contract address where the vault has deposited and which is associated
     * to a staking pool where to unstake all lpTokens
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getUnstakeAllCodes(address payable _vault, address _liquidityPool)
        external
        view
        returns (bytes[] memory _codes);

    /**
     * @notice Returns the balance in underlying for staked lpToken balance of vault
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address which is associated with staking pool from where to
     * get amount of staked lpToken
     * @return Returns the underlying token amount for the staked lpToken
     */
    function getAllAmountInTokenStake(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) external view returns (uint256);

    /**
     * @notice Returns amount of lpTokens staked by the vault
     * @param _vault Vault contract address
     * @param _liquidityPool Liquidity pool's contract address from where to get the lpToken balance
     * @return Returns the lpToken balance that is staked by the specified vault
     */
    function getLiquidityPoolTokenBalanceStake(address payable _vault, address _liquidityPool)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the equivalent amount in underlying token if the given amount of lpToken is unstaked and redeemed
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to get amount to redeem
     * @param _redeemAmount Amount of lpToken to redeem for staking
     * @return _amount Returns the lpToken amount that can be redeemed
     */
    function calculateRedeemableLPTokenAmountStake(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) external view returns (uint256 _amount);

    /**
     * @notice Checks whether the given amount of underlying token can be received for full balance of staked lpToken
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address where to check the redeem amt is enough to stake
     * @param _redeemAmount amount specified underlying token that can be received for full balance of staking lpToken
     * @return Returns a boolean true if _redeemAmount is enough to stake and false if not enough
     */
    function isRedeemableAmountSufficientStake(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) external view returns (bool);

    /**
     * @notice Get the batch of function calls for unstake and redeem specified amount of shares
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address associated to a staking pool from where to unstake
     * and then withdraw
     * @param _redeemAmount Amount of lpToken to unstake and redeem
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getUnstakeAndWithdrawSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) external view returns (bytes[] memory _codes);

    /**
     * @notice Get the batch of function calls for unstake and redeem whole balance of shares held in a vault
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address associated to a staking pool from where to unstake
     * and then withdraw
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getUnstakeAndWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) external view returns (bytes[] memory _codes);
}