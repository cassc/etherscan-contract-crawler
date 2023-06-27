//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface Incentivization {
    function claim(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external;
}