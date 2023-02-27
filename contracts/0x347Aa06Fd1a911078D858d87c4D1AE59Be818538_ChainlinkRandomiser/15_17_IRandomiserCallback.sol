// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

interface IRandomiserCallback {
    function receiveRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) external;
}