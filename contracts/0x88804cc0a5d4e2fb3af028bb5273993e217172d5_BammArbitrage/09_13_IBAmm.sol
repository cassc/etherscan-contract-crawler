// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBAmm {
    /**
     * @notice Swaps an amount of LUSD for ETH.
     * @param lusdAmount The amount of LUSD to swap.
     * @param minEthReturn The minimum amount of ETH to receive.
     * @param dest The address to send the ETH to.
     * @return The amount of ETH received.
     */
    function swap(uint lusdAmount, uint minEthReturn, address payable dest) external returns(uint);

    /**
    * @notice Calculates the total value of the pool in LUSD.
    *
    * @return totalLUSDValue The total value of the pool in LUSD.
    * @return lusdBalance The amount of LUSD in the pool.
    * @return ethLUSDValue The value of the ETH in the pool in LUSD.
    */
    function getLUSDValue()  external view returns(uint totalLUSDValue, uint lusdBalance, uint ethLUSDValue);

    /**
    * @notice Calculates the amount of ETH to swap for a given amount of LUSD.
    *
    * @param lusdQty The amount of LUSD to swap.
    *
    * @return ethAmount The amount of ETH to swap.
    * @return feeLusdAmount The amount of LUSD to pay as a fee.
    */
    function getSwapEthAmount(uint lusdQty) external view returns(uint ethAmount, uint feeLusdAmount);
}