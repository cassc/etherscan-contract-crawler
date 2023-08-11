// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for borrow feature for DeFi adapters
 * @author Opty.fi
 * @notice Interface of the DeFi protocol adapter for borrow functionality
 * @dev Abstraction layer to different DeFi protocols like AaveV1, AaveV2 etc. which has borrow feature
 * It is used as a layer for adding any new functions in DeFi adapters if they include borrow functionality
 * Conventions used:
 *  - lpToken: liquidity pool token
 */
interface IAdapterBorrow {
    /**
     * @dev Get batch of function calls for token amount that can be borrowed safely against the underlying token
     * when kept as collateral
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to borrow
     * @param _outputToken Token address to borrow
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getBorrowAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        address _outputToken
    ) external view returns (bytes[] memory _codes);

    /**
     * @dev Get batch of function calls require to repay debt, unlock collateral and redeem lpToken
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token supported by the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address for all protocols except for Aave where it is
     * liquidity pool address provider's contract address
     * @param _outputToken Token address to borrow
     * @return _codes Returns an array of bytes in sequence that can be executed by vault
     */
    function getRepayAndWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        address _outputToken
    ) external view returns (bytes[] memory _codes);

    /**
     * @notice Get the amount in underlying token that you'll receive if borrowed token is repaid
     * @dev Returns the amount in underlying token for _liquidityPoolTokenAmount collateral if
     * _borrowAmount in _borrowToken is repaid.
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address for the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to borrow the tokens
     * @param _borrowToken Token address to borrow
     * @param _borrowAmount Amount of token to borrow
     * @return Returns the amount in underlying token that can be received if borrowed token is repaid
     */
    function getSomeAmountInTokenBorrow(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _liquidityPoolTokenAmount,
        address _borrowToken,
        uint256 _borrowAmount
    ) external view returns (uint256);

    /**
     * @notice Get the amount in underlying token that you'll receive if whole balance of vault borrowed token is repaid
     * @dev Returns the amount in underlying token for whole collateral of _vault balance if
     * _borrowAmount in _borrowToken is repaid.
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address for the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address from where to borrow the tokens
     * @param _borrowToken Token address to borrow
     * @param _borrowAmount Amount of token to borrow
     * @return Returns amount in underlyingToken that you'll receive if whole balance of vault borrowed token is repaid
     */
    function getAllAmountInTokenBorrow(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        address _borrowToken,
        uint256 _borrowAmount
    ) external view returns (uint256);
}