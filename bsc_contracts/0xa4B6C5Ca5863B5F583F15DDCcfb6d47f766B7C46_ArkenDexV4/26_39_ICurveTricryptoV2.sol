// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ICurveTricryptoV2 {
    function exchange(
        uint256 tokenIndexFrom,
        uint256 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        bool useEth
    ) external;
}