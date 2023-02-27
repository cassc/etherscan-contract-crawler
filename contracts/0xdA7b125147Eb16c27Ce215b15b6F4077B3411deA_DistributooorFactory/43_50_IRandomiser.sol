// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IRandomiser {
    function getRandomNumber(
        address callbackContract
    ) external returns (uint256 requestId);
}