// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IOracle {
    /**
     * @notice function checks oracle validity and calculates collTokenPriceInLoanToken
     * @param collToken address of coll token
     * @param loanToken address of loan token
     * @return collTokenPriceInLoanToken collateral price denominated in loan token
     */
    function getPrice(
        address collToken,
        address loanToken
    ) external view returns (uint256 collTokenPriceInLoanToken);

    /**
     * @notice function checks oracle validity and retrieves prices in base currency unit
     * @param collToken address of coll token
     * @param loanToken address of loan token
     * @return collTokenPriceRaw and loanTokenPriceRaw denominated in base currency unit
     */
    function getRawPrices(
        address collToken,
        address loanToken
    )
        external
        view
        returns (uint256 collTokenPriceRaw, uint256 loanTokenPriceRaw);
}