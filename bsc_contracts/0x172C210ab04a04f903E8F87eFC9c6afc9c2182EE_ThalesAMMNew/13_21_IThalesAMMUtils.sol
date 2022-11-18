// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

interface IThalesAMMUtils {
    function calculateOdds(
        uint _price,
        uint strike,
        uint timeLeftInDays,
        uint volatility
    ) external view returns (uint);
}