// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// https://etherscan.io/address/0xDC24316b9AE028F1497c275EB9192a3Ea0f67022#code
interface IStEthEthPool {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);
}