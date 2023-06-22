// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface ICurvePool {
    function add_liquidity(uint256[2] calldata amounts, uint256 minAmount)
        external
        payable;

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy,
        bool useEth,
        address receiver
    ) external payable returns (uint256);

    function coins(uint256 i) external view returns (address);
}