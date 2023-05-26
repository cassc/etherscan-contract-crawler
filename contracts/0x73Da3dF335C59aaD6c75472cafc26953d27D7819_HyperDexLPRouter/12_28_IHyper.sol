// SPDX-License-Identifier: MIT

/***
 *      ______             _______   __
 *     /      \           |       \ |  \
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *
 *
 *
 */

pragma solidity ^0.8.4;

library TYPES {
    struct UPoolAttributes {
        address tokenA;
        address tokenB;
        uint24 uniFee;
    }

    struct HPoolAttributes {
        address tokenA;
        address tokenB;
        uint24 uniFee;
        int24 lowerTick;
        int24 upperTick;
        address manager;
        uint16 managerFee;
    }
}

interface IHyperLPFactory {
    event PoolCreated(
        address indexed uniPool,
        address indexed manager,
        address indexed pool
    );

    function createPool(TYPES.HPoolAttributes calldata attributes)
        external
        returns (address pool);

    function getPools(
        address deployer,
        TYPES.UPoolAttributes calldata attributes
    ) external view returns (address[] memory);

    function numPools(TYPES.UPoolAttributes calldata attributes)
        external
        view
        returns (uint256);

    function numDeployerPools(
        address deployer,
        TYPES.UPoolAttributes calldata attributes
    ) external view returns (uint256);

    function isTrustedPool(address pool) external view returns (bool);
}

interface IHyperLPool {
    function getMintAmounts(uint256 amount0Max, uint256 amount1Max)
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount,
            uint160 sqrtRatioX96
        );

    function mint(
        uint256 amount0Max,
        uint256 amount1Max,
        address receiver
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount,
            uint128 liquidityMinted
        );

    function burn(uint256 burnAmount, address receiver)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        );
}