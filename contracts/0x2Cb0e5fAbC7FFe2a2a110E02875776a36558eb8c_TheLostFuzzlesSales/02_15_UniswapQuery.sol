// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IPairERC20 {
    function decimals() external view returns (uint256);
}

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );

    function token1() external view returns (address);
}

contract UniswapQuery {
    function getGalaAmount(uint256 ethAmount) public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(
            0xbe19C32B4CD202407e8eEB73e4E2949438461Ae3
        ); // GALA/ETH pair

        IPairERC20 token1 = IPairERC20(pair.token1());

        (uint256 res0, uint256 res1, ) = pair.getReserves();

        uint256 token1Decimal = 10**token1.decimals();

        return (((ethAmount * res0) * token1Decimal) / res1) / token1Decimal; // amount of GALA needed to buy ETH amount
    }
}