// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IComptrollerVenus {
    function enterMarkets(address[] calldata xTokens)
        external
        returns (uint256[] memory);

    function markets(address cTokenAddress)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface IDistributionVenus {
    function claimVenus(address holder, address[] memory vTokens) external;
}