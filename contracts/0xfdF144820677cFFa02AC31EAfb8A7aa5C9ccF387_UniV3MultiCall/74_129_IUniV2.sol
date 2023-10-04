// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IUniV2 {
    /**
     * @notice returns reserves of uni v2 pool
     * @return token0 reserves
     * @return token1 reserves
     * @return timestamp
     */
    function getReserves() external view returns (uint112, uint112, uint32);

    /**
     * @notice token0 address of pool
     */
    function token0() external view returns (address);

    /**
     * @notice token1 address of pool
     */
    function token1() external view returns (address);

    /**
     * @notice totalSupply of the lp token
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice decimals of the lp token
     */
    function decimals() external view returns (uint256);
}