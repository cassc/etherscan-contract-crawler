// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

interface IPrizeDistributionFactory {
    function pushPrizeDistribution(
        uint32 _drawId,
        uint256 _totalNetworkTicketSupply
    ) external;
}