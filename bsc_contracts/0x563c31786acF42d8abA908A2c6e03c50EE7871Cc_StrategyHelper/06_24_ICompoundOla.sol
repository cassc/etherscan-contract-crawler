// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IComptrollerOla {
    function enterMarkets(address[] calldata xTokens)
        external
        returns (uint256[] memory);

    function markets(address cTokenAddress)
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getAllMarkets() external view returns (address[] memory);

    function getUnderlyingPriceInLen(address underlying)
        external
        view
        returns (uint256);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface IDistributionOla {
    function claimComp(address holder, address[] calldata cTokens) external;

    function compAccrued(address holder) external returns (uint256);
}