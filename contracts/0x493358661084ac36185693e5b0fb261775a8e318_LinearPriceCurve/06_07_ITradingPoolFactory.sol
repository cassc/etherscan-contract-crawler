//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

interface ITradingPoolFactory {
    event CreateTradingPool(
        address indexed pool,
        address indexed nft,
        address indexed token
    );
    event SetTradingPool(
        address indexed pool,
        address indexed nft,
        address indexed token
    );

    function getProtocolFeePercentage() external view returns (uint256);

    function getTVLSafeguard() external view returns (uint256);

    function isTradingPool(address pool) external view returns (bool);

    function isPriceCurve(address priceCurve) external view returns (bool);
}