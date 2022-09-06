// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface ISmoothyV1 {
    function swap(
        uint256 bTokenIdxIn,
        uint256 bTokenIdxOut,
        uint256 bTokenInAmount,
        uint256 bTokenOutMin
    ) external;
}