// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface ICurvePool {
    function coins(uint256 idx) external view returns (address);

    // @notice Perform an exchange between two coins
    // @dev Index values can be found via the `coins` public getter method
    // @dev see: https://etherscan.io/address/0xDC24316b9AE028F1497c275EB9192a3Ea0f67022#readContract
    // @param i Index value for the stEth to send -- 1
    // @param j Index value of the Eth to recieve -- 0
    // @param dx Amount of `i` (stEth) being exchanged
    // @param minDy Minimum amount of `j` (Eth) to receive
    // @return Actual amount of `j` (Eth) received
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external payable returns (uint256);
}