// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**
 * @title  LoanCurrencyWhitelist
 * @author Solarr
 * @notice
 */
interface ILoanCurrencyWhitelist {
    /**
     * @notice This function can be called by Owner to list LoanCurrency to Whitelist.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     * @param _name - The name of the LoanCurrency.
     */
    function whitelistLoanCurrency(
        address _loanCurrencyAddress,
        string calldata _name
    ) external;

    /**
     * @notice This function can be called by Owner to unlist LoanCurrency from Whitelist.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     */
    function unwhitelistLoanCurrency(address _loanCurrencyAddress) external;

    /**
     * @notice This function can be called by Anyone to know the LoanCurrency is listed in Whitelist or not.
     *
     * @param _loanCurrencyAddress - The address of the LoanCurrency contract.
     *
     * @return Returns whether the LoanCurrency is whitelisted
     */
    function isLoanCurrencyWhitelisted(address _loanCurrencyAddress)
        external
        view
        returns (bool);
}