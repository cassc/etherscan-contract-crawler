// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

import './PeripheryImmutableState.sol';
import '../interfaces/IPoolInitializer.sol';

/// @title Creates and initializes V3 Pools
abstract contract PoolInitializer is IPoolInitializer, PeripheryImmutableState {

    mapping(address => uint) public poolCreationDates;
    mapping(uint => address) public poolsAddresses;
    uint public poolsCount;

//    mapping(address => bool) public tokenPresented;
//    mapping(uint => address) public tokensAddresses;
//    uint public tokensAddressesCount;

    /// @inheritdoc IPoolInitializer
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable override returns (address pool) {
        require(token0 < token1);
        pool = IUniswapV3Factory(factory).getPool(token0, token1, fee);

        if (pool == address(0)) {
            pool = IUniswapV3Factory(factory).createPool(token0, token1, fee);
            IUniswapV3Pool(pool).initialize(sqrtPriceX96);
            poolCreationDates[pool] = block.timestamp;
            poolsAddresses[poolsCount] = pool;
            poolsCount++;
//            if (tokenPresented[token0] == false) {
//                tokenPresented[token0] = true;
//                tokensAddresses[tokensAddressesCount] = token0;
//                tokensAddressesCount++;
//            }
//            if (tokenPresented[token1] == false) {
//                tokenPresented[token1] = true;
//                tokensAddresses[tokensAddressesCount] = token1;
//                tokensAddressesCount++;
//            }
        } else {
            (uint160 sqrtPriceX96Existing, , , , , , ) = IUniswapV3Pool(pool).slot0();
            if (sqrtPriceX96Existing == 0) {
                IUniswapV3Pool(pool).initialize(sqrtPriceX96);
            }
        }
    }
}