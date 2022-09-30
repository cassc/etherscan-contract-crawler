// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface to a LoanPriceOracle
 */
interface ILoanPriceOracle {
    /**************************************************************************/
    /* Error codes */
    /**************************************************************************/

    /**
     * @notice Unsupported collateral token contract
     */
    error UnsupportedCollateral();
    /**
     * @notice Insufficient time remaining for loan
     */
    error InsufficientTimeRemaining();
    /**
     * @notice Loan parameter out of bounds
     * @param index Index of out of bound parameter
     */
    error ParameterOutOfBounds(uint256 index);

    /**************************************************************************/
    /* Getters */
    /**************************************************************************/

    /**
     * @notice Get currency token used for pricing
     * @return Currency token contract
     */
    function currencyToken() external view returns (IERC20);

    /**************************************************************************/
    /* Primary API */
    /**************************************************************************/

    /**
     * @notice Price a loan collateralized by the specified token contract and
     * token id
     * @param collateralToken Collateral token contract
     * @param collateralTokenId Collateral token ID
     * @param principal Principal value of loan, in UD60x18
     * @param repayment Repayment value of loan, in UD60x18
     * @param duration Duration of loan, in seconds
     * @param maturity Maturity of loan, in seconds since Unix epoch
     * @param utilization Vault fund utilization, in UD60x18
     * @return Price of loan, in UD60x18
     */
    function priceLoan(
        address collateralToken,
        uint256 collateralTokenId,
        uint256 principal,
        uint256 repayment,
        uint256 duration,
        uint256 maturity,
        uint256 utilization
    ) external view returns (uint256);

    /**
     * @notice Price a loan's repayment, collateralized by the specified token
     * contract and token id
     * @param collateralToken Collateral token contract
     * @param collateralTokenId Collateral token ID
     * @param principal Principal value of loan, in UD60x18
     * @param duration Duration of loan, in seconds
     * @param utilization Vault fund utilization, in UD60x18
     * @return Repayment price of loan, in UD60x18
     */
    function priceLoanRepayment(
        address collateralToken,
        uint256 collateralTokenId,
        uint256 principal,
        uint256 duration,
        uint256 utilization
    ) external view returns (uint256);
}