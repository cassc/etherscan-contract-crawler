// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title V2 of DeFi Adapter for opty.fi
 * @author Opty.fi
 * @notice Interface with minimal functions to be inhertied in special defi adapters
 * @dev Abstraction layer to different DEX protocols like Sushi, Curve, Uniswap
 * It is used as a layer for adding any new function which will be used in all DeFi adapters
 */
interface IAdapterV2 {
    /**
     * @dev Get batch of function calls for depositing specified amount of underlying token in given liquidity pool
     * @param _vault Vault contract address
     * @param _underlyingToken  Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address where to deposit
     * @param _outputToken address of token received after supplying liquidity
     * @param _amount Underlying token's amount
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getDepositSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        address _outputToken,
        uint256 _amount
    ) external view returns (bytes[] memory _codes);

    /**
     * @dev Get batch of function calls for depositing vault's full balance in underlying tokens in given liquidity pool
     * @param _vault Vault contract address
     * @param _underlyingToken  Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address where to deposit
     * @param _outputToken address of token received after supplying liquidity
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getDepositAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        address _outputToken
    ) external view returns (bytes[] memory _codes);

    /**
     * @notice Get batch of function calls for redeeming specified amount of lpTokens held in the vault
     * @dev Redeem specified `amount` of `liquidityPoolToken` and send the `underlyingToken` to the caller`
     * @param _vault Vault contract address
     * @param _underlyingToken  Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to withdraw
     * @param _outputToken address of token to be withdrawn
     * @param _amount Amount of underlying token to redeem from the given liquidity pool
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getWithdrawSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        address _outputToken,
        uint256 _amount
    ) external view returns (bytes[] memory _codes);

    /**
     * @notice Get batch of function calls for redeeming full balance of lpTokens held in the vault
     * @dev Redeem full `amount` of `liquidityPoolToken` and send the `underlyingToken` to the caller`
     * @param _vault Vault contract address
     * @param _underlyingToken  Underlying token's address supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to withdraw
     * @param _outputToken address of token to be withdrawn
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        address _outputToken
    ) external view returns (bytes[] memory _codes);

    /**
     * @dev Returns the market value in underlying for all the lpTokens held in a specified liquidity pool
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address for which to get the balance
     * @param _liquidityPool Liquidity pool's contract address which holds the given underlying token
     * @param _outputToken address of output token
     * @return Returns the amount of underlying token balance
     */
    function getAllAmountInToken(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        address _outputToken
    ) external view returns (uint256);

    /**
     * @notice Get the balance of vault in lpTokens in the specified liquidity pool
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address supported by given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to get the balance of lpToken
     * @param _outputToken address of the output token
     * @return Returns the balance of lpToken (lpToken)
     */
    function getLiquidityPoolTokenBalance(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        address _outputToken
    ) external view returns (uint256);

    /**
     * @notice Returns the equivalent value of underlying token for given amount of lpToken
     * @param _underlyingToken Underlying token address supported by given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to get the balance of lpToken
     * @param _outputToken address of output token
     * @param _outputTokenAmount LpToken amount for which to get equivalent underlyingToken amount
     * @return Returns the equivalent amount of underlying token for given lpToken amount
     */
    function getSomeAmountInToken(
        address _underlyingToken,
        address _liquidityPool,
        address _outputToken,
        uint256 _outputTokenAmount
    ) external view returns (uint256);

    /**
     * @dev Returns the equivalent value of lpToken for given amount of underlying token
     * @param _underlyingToken Underlying token address for the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to redeem the tokens
     * @param _outputToken address of output token
     * @param _underlyingTokenAmount Amount of underlying token to be calculated w.r.t. lpToken
     * @return Returns the calculated amount of lpToken equivalent to underlyingTokenAmount
     */
    function calculateAmountInLPToken(
        address _underlyingToken,
        address _liquidityPool,
        address _outputToken,
        uint256 _underlyingTokenAmount
    ) external view returns (uint256);
}