// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICurrencyManager {
    function addCurrency(address policy) external;

    function removeCurrency(address policy) external;

    function isCurrencyWhitelisted(address policy) external view returns (bool);

    function viewWhitelistedCurrencies(
        uint256 cursor,
        uint256 size
    ) external view returns (address[] memory, uint256);

    function viewCountWhitelistedCurrencies() external view returns (uint256);
}