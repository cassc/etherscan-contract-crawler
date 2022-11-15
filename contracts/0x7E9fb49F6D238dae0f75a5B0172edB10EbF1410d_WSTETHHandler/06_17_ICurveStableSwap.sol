// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.6;

interface ICurveStableSwap {
    // @notice Perform an exchange between two coins
    // @dev Index values can be found via the `coins` public getter method
    // @dev see: https://etherscan.io/address/0xDC24316b9AE028F1497c275EB9192a3Ea0f67022#readContract
    // @param i Index value for the stEth to send -- 1
    // @param j Index value of the Eth to recieve -- 0
    // @param dx Amount of `i` (stEth) being exchanged
    // @param minDy Minimum amount of `j` (Eth) to receive
    // @return Actual amount of `j` (Eth) received
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external payable returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}