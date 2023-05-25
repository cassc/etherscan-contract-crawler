// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IPriceFeed {
    function getThePrice(address tokenFeed) external view returns (int256);

    function setPriceFeed(address token, address feed) external;

    function getFeed(address token) external view returns (address);
}