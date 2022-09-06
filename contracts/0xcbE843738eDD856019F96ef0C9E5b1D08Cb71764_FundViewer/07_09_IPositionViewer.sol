// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

interface IPositionViewer {

    function query(uint256 tokenId) external view returns (
        address token0,
        address token1,
        uint24 fee,
        uint256 amount0,
        uint256 amount1,
        uint256 fee0,
        uint256 fee1
    );

}