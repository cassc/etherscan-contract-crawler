// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ICSwapCurve {
    /** @notice There are different interfaces for different CurvePools. This allows the user
    to specify which pool interface to utilise.
        @param STABLESWAP_EXCHANGE A swap using the StableSwap pools
        @param STABLESWAP_UNDERLYING A swap using the lending version of a StableSwap pool
        @param CRYPTOSWAP_EXCHANGE A swap using the CryptoSwap pools
        @param CRYPTOSWAP_UNDERLYING A swap using the lending versions of a CryptoSwap pool
     */
    enum CurveSwapType {
        STABLESWAP_EXCHANGE,
        STABLESWAP_UNDERLYING,
        CRYPTOSWAP_EXCHANGE,
        CRYPTOSWAP_UNDERLYING
    }

    /** @notice Used to specify Curve specific parameters for CSwap
        @dev Note that older curve pools use int128 for i/j. Here, we use uint256 for all.
        @param poolAddress The address of the CurvePool being used to swap with.
        @param tokenI The index of the input token within the CurvePool.
        @param tokenJ The index of the output token within the CurvePool.
        @param swapType 
     */
    struct CurveSwapParams {
        address poolAddress;
        uint256 tokenI;
        uint256 tokenJ;
        CurveSwapType swapType;
    }
}