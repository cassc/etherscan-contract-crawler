// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20PairToken.sol";

interface IERC20Pair is IERC20PairToken {
    function swap(
        uint256 amountOfAsset1,
        uint256 amountOfAsset2,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount1, uint256 amount2);
}