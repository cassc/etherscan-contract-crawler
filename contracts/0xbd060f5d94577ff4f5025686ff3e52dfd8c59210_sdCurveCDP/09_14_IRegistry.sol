// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Iregistry {
    function exchange_multiple(
        address[9] calldata _pool,
        uint256[3][4] calldata i,
        uint256 _amountA,
        uint256 _amountB,
        address[4] calldata addresses
    ) external;

    function exchange_with_best_rate(
        address,
        address,
        uint256,
        uint256
    ) external returns (uint256);
}