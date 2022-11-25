// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

import "../interfaces/IPair.sol";
import "../interfaces/IFactory.sol";
import "../Pair.sol";

library Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(
        address token0,
        address token1
    ) public pure returns (address tokenA, address tokenB) {
        require(token0 != token1, "Library: Identical Addresses");
        (tokenA, tokenB) = token0 < token1
            ? (token0, token1)
            : (token1, token0);
        require(tokenA != address(0), "Library: Zero Address");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address token0,
        address token1
    ) public view returns (address pair) {
        (address tokenA, address tokenB) = sortTokens(token0, token1);
        bytes memory bytecode = type(Pair).creationCode;
        bytes memory bytecodeArg = abi.encodePacked(
            bytecode,
            abi.encode(tokenA, tokenB, IFactory(factory).twammAdd())
        );
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            factory,
                            keccak256(abi.encodePacked(tokenA, tokenB)),
                            keccak256(bytecodeArg)
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address token0,
        address token1
    ) public view returns (uint256 reserve0, uint256 reserve1) {
        (address tokenA, ) = sortTokens(token0, token1);
        uint256 reserveA = IPair(pairFor(factory, token0, token1))
            .tokenAReserves();
        uint256 reserveB = IPair(pairFor(factory, token0, token1))
            .tokenBReserves();
        (reserve0, reserve1) = token0 == tokenA
            ? (reserveA, reserveB)
            : (reserveB, reserveA);
    }

    // sorts the amounts for tokens
    function sortAmounts(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) public pure returns (uint256 amountA, uint256 amountB) {
        (address tokenA, ) = sortTokens(token0, token1);
        (amountA, amountB) = token0 == tokenA
            ? (amount0, amount1)
            : (amount1, amount0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amount0,
        uint256 reserve0,
        uint256 reserve1
    ) public pure returns (uint256 amount1) {
        require(amount0 > 0, "Library: Insufficient Amount");
        require(
            reserve0 > 0 && reserve1 > 0,
            "Library: Insufficient_Liquidity"
        );
        amount1 = (amount0 * reserve1) / reserve0;
    }
}