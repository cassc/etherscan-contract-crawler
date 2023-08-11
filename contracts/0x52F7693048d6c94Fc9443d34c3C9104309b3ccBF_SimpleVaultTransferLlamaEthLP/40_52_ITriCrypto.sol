// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title interface for Curve TriCrypto (USDT, WBTC, WETH) pool
 */
interface ITriCrypto {
    /**
     * @notice Perform an exchange between two underlying coins
     * @param i Index value for the underlying coin to send
     * @param j Index valie of the underlying coin to receive
     * @param _dx Amount of `i` being exchanged
     * @param _min_dy Minimum amount of `j` to receive
     * @param use_eth boolean indicating whether ETH should be used in exchange
     * @return Actual amount of `j` received
     */
    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy,
        bool use_eth
    ) external payable returns (uint256);
}