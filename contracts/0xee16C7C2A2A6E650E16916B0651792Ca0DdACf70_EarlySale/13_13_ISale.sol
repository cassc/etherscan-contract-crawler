// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Shared interface for EarlySale + StaakeSale
interface ISale {
    /**
     * @notice View the price of STK tokens in USD
     */
    function STK_USD_VALUE() external view returns (uint256);

    /**
     * @notice View the number of decimals (precision) for `STK_USD_VALUE`
     */
    function STK_USD_DECIMALS() external view returns (uint8);

    /**
     * @notice View the minimum amount of ETH per call
     */
    function MIN_INVESTMENT() external view returns (uint256);

    /**
     * @notice View the maximum total amount of ETH per investor
     */
    function MAX_INVESTMENT() external view returns (uint256);

    /**
     * @notice View the amount of STK still available for sale
     */
    function availableTokens() external view returns (uint256);

    /**
     * @notice Reserves STK tokens at the current ETH/USD exchange rate
     */
    function buy() external payable;

    /**
     * @notice View the total amount of STK tokens a user has bought
     * @param _user, address of the user
     */
    function balanceOf(address _user) external view returns (uint256);

    /**
     * @notice View the total amount of ETH spent by a user
     * @param _user, address of the user
     */
    function getETHSpent(address _user) external view returns (uint256);
}