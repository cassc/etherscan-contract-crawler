// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

library TOKordinatorLibrary {
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'TOKordinator: identical addresses');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TOKordinator: zero address');
    }
}