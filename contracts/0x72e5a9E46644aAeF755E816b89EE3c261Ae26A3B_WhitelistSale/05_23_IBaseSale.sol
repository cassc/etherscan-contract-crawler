// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

interface IBaseSale {
    function treasury() external view returns (address payable);

    function whitelist() external view returns (address);

    // @dev Start sales.
    function start() external;

    // @dev Stop sales.
    function stop() external;

    function getPrice() external view returns (uint256 price);

    function setDefaultPrice(uint256 price) external;
}