// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface ICryptoPool {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 amount
    ) external view returns (uint256);

    function get_dy_underlying(
        uint256 i,
        uint256 j,
        uint256 amount
    ) external view returns (uint256);
}