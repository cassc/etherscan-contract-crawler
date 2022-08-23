// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IBotChecker {
    function checkBots(
        address _from,
        address _to,
        uint256 _amount
    ) external;
}