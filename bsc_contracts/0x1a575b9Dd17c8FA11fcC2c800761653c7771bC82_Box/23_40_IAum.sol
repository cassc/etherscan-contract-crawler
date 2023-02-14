// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

struct Balance {
    address asset;
    uint256 balance;
}

struct Valuation {
    address asset;
    uint256 valuation;
}

interface IAum {
    function getAssetBalances() external view returns (Balance[] memory);

    function getLiabilityBalances() external view returns (Balance[] memory);

    function getAssetValuations(bool shouldMaximise, bool shouldIncludeAmmPrice)
        external
        view
        returns (Valuation[] memory);

    function getLiabilityValuations(
        bool shouldMaximise,
        bool shouldIncludeAmmPrice
    ) external view returns (Valuation[] memory);

    function getEquityValuation(bool shouldMaximise, bool shouldIncludeAmmPrice)
        external
        view
        returns (uint256);

    function getInvestmentTokenSupply() external view returns (uint256);

    function getInvestmentTokenBalanceOf(address user)
        external
        view
        returns (uint256);
}