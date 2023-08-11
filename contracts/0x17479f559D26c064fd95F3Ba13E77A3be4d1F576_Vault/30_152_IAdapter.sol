// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for all the DeFi adapters
 * @author Opty.fi
 * @notice Interface with minimal functions to be inhertied in all DeFi adapters
 * @dev Abstraction layer to different DeFi protocols like AaveV1, Compound etc.
 * It is used as a layer for adding any new function which will be used in all DeFi adapters
 * Conventions used:
 *  - lpToken: liquidity pool token
 */
interface IAdapter {
    /**
     * @notice Returns pool value in underlying token (for all adapters except Curve for which the poolValue is
     * in US dollar) for the given liquidity pool and underlyingToken
     * @dev poolValue can be in US dollar for protocols like Curve if explicitly specified, underlyingToken otherwise
     * for protocols like Compound etc.
     * @param _liquidityPool Liquidity pool's contract address
     * @param _underlyingToken Contract address of the liquidity pool's underlying token
     * @return Pool value in underlying token for the given liquidity pool and underlying token
     */
    function getPoolValue(address _liquidityPool, address _underlyingToken) external view returns (uint256);

    /**
     * @dev Get batch of function calls for depositing specified amount of underlying token in given liquidity pool
     * @param _vault Vault contract address
     * @param _underlyingToken  Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address where to deposit
     * @param _amount Underlying token's amount
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getDepositSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _amount
    ) external view returns (bytes[] memory _codes);

    /**
     * @dev Get batch of function calls for depositing vault's full balance in underlying tokens in given liquidity pool
     * @param _vault Vault contract address
     * @param _underlyingToken  Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address where to deposit
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getDepositAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) external view returns (bytes[] memory _codes);

    /**
     * @notice Get batch of function calls for redeeming specified amount of lpTokens held in the vault
     * @dev Redeem specified `amount` of `liquidityPoolToken` and send the `underlyingToken` to the caller`
     * @param _vault Vault contract address
     * @param _underlyingToken  Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to withdraw
     * @param _amount Amount of underlying token to redeem from the given liquidity pool
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getWithdrawSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _amount
    ) external view returns (bytes[] memory _codes);

    /**
     * @notice Get batch of function calls for redeeming full balance of lpTokens held in the vault
     * @dev Redeem full `amount` of `liquidityPoolToken` and send the `underlyingToken` to the caller`
     * @param _vault Vault contract address
     * @param _underlyingToken  Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to withdraw
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) external view returns (bytes[] memory _codes);

    /**
     * @notice Get the lpToken address
     * @param _underlyingToken Underlying token address
     * @param _liquidityPool Liquidity pool's contract address from where to get the lpToken
     * @return Returns the lpToken address
     */
    function getLiquidityPoolToken(address _underlyingToken, address _liquidityPool) external view returns (address);

    /**
     * @notice Get the underlying token addresses given the liquidity pool and/or lpToken
     * @dev there are some defi pools which requires liqudiity pool and lpToken's address to return underlying token
     * @param _liquidityPool Liquidity pool's contract address from where to get the lpToken
     * @param _liquidityPoolToken LpToken's address
     * @return _underlyingTokens Returns the array of underlying token addresses
     */
    function getUnderlyingTokens(address _liquidityPool, address _liquidityPoolToken)
        external
        view
        returns (address[] memory _underlyingTokens);

    /**
     * @dev Returns the market value in underlying for all the lpTokens held in a specified liquidity pool
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address for which to get the balance
     * @param _liquidityPool Liquidity pool's contract address which holds the given underlying token
     * @return Returns the amount of underlying token balance
     */
    function getAllAmountInToken(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) external view returns (uint256);

    /**
     * @notice Get the balance of vault in lpTokens in the specified liquidity pool
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address supported by given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to get the balance of lpToken
     * @return Returns the balance of lpToken (lpToken)
     */
    function getLiquidityPoolTokenBalance(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) external view returns (uint256);

    /**
     * @notice Returns the equivalent value of underlying token for given amount of lpToken
     * @param _underlyingToken Underlying token address supported by given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to get the balance of lpToken
     * @param _liquidityPoolTokenAmount LpToken amount for which to get equivalent underlyingToken amount
     * @return Returns the equivalent amount of underlying token for given lpToken amount
     */
    function getSomeAmountInToken(
        address _underlyingToken,
        address _liquidityPool,
        uint256 _liquidityPoolTokenAmount
    ) external view returns (uint256);

    /**
     * @dev Returns the equivalent value of lpToken for given amount of underlying token
     * @param _underlyingToken Underlying token address for the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to redeem the tokens
     * @param _underlyingTokenAmount Amount of underlying token to be calculated w.r.t. lpToken
     * @return Returns the calculated amount of lpToken equivalent to underlyingTokenAmount
     */
    function calculateAmountInLPToken(
        address _underlyingToken,
        address _liquidityPool,
        uint256 _underlyingTokenAmount
    ) external view returns (uint256);

    /**
     * @dev Returns the market value in underlying token of the shares in the specified liquidity pool
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address for the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to redeem the tokens
     * @param _redeemAmount Amount of token to be redeemed
     * @return _amount Returns the market value in underlying token of the shares in the given liquidity pool
     */
    function calculateRedeemableLPTokenAmount(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) external view returns (uint256 _amount);

    /**
     * @notice Checks whether the vault has enough lpToken (+ rewards) to redeem for the specified amount of shares
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address for the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to redeem the tokens
     * @param _redeemAmount Amount of lpToken (+ rewards) enough to redeem
     * @return Returns a boolean true if lpToken (+ rewards) to redeem for given amount is enough else it returns false
     */
    function isRedeemableAmountSufficient(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) external view returns (bool);

    /**
     * @notice Returns reward token address for the liquidity pool provided
     * @param _liquidityPool Liquidity pool's contract address for which to get the reward token address
     * @return Returns the reward token supported by given liquidity pool
     */
    function getRewardToken(address _liquidityPool) external view returns (address);

    /**
     * @notice Returns whether the protocol can stake lpToken
     * @param _liquidityPool Liquidity pool's contract address for which to check if staking is enabled or not
     * @return Returns a boolean true if lpToken staking is allowed else false if it not enabled
     */
    function canStake(address _liquidityPool) external view returns (bool);
}