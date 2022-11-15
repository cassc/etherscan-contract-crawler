// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}
