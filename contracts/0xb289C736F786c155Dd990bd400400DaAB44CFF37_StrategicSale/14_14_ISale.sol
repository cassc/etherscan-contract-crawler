// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/// @title Shared interface for EarlySale + SpaaceSale
interface ISale {
    /**
     * @notice Reserves tokens at the current ETH/USD exchange rate
     */
    function buy() external payable;

    /**
     * @notice View the price of the token in USD
     */
    // solhint-disable-next-line func-name-mixedcase
    function TOKEN_USD_PRICE() external view returns (uint128);

    /**
     * @notice View the number of decimals (precision) for `TOKEN_USD_PRICE`
     */
    // solhint-disable-next-line func-name-mixedcase
    function TOKEN_USD_PRICE_DECIMALS() external view returns (uint8);

    /**
     * @notice View the minimum amount of ETH per call
     */
    // solhint-disable-next-line func-name-mixedcase
    function MIN_INVESTMENT() external view returns (uint128);

    /**
     * @notice View the maximum total amount of ETH per investor
     */
    // solhint-disable-next-line func-name-mixedcase
    function MAX_INVESTMENT() external view returns (uint128);

    /**
     * @notice View the amount of tokens still available for sale
     */
    function availableTokens() external view returns (uint128);

    /**
     * @notice View the total amount of tokens a user has bought
     * @param _user, address of the user
     */
    function balanceOf(address _user) external view returns (uint128);

    /**
     * @notice View the total amount of ETH spent by a user
     * @param _user, address of the user
     */
    function getETHSpent(address _user) external view returns (uint128);
}