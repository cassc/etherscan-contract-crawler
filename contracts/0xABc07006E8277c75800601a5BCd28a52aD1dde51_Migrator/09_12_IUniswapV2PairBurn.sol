// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface IUniswapV2PairBurn {
    function transferFrom(address from, address to, uint value) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function burn(address to) external returns (uint amount0, uint amount1);
}