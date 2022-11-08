// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface to a Collateral Oracle
 */
interface ICollateralOracle {
    /**************************************************************************/
    /* Error codes */
    /**************************************************************************/

    /**
     * @notice Unsupported collateral token
     */
    error UnsupportedCollateral();

    /**************************************************************************/
    /* Getters */
    /**************************************************************************/

    /**
     * @notice Get currency token used for pricing
     * @return Currency token contract
     */
    function currencyToken() external view returns (IERC20);

    /**
     * @notice Get collateral value
     * @param collateralToken Collateral token contract
     * @param collateralTokenId Collateral token ID
     * @return Collateral value
     */
    function collateralValue(address collateralToken, uint256 collateralTokenId) external view returns (uint256);
}