//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IOracle {
    function oracle() external view returns (address);

    function getLatestPrice(address token) external view returns (uint256 price);

    function scalePrice(
        uint256 _price,
        uint8 _quoteDecimals,
        uint8 _baseDecimals
    ) external pure returns (uint256);

    function setFeeds(
        address[] memory _tokens,
        address[] memory _baseDecimals,
        address[] memory _aggregators
    ) external;

    function getResponseDecimals(address token) external view returns(uint8);
    function getBaseDecimals(address token) external view returns (uint8);
}