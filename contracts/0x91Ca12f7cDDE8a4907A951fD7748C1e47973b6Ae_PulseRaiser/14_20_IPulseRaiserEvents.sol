// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IPulseRaiserEvents {
    event PriceBaseModified(uint8 indexed day, uint16 indexed base);
    event PriceBasesBatchModified();
    event PointsGained(address indexed account, uint256 indexed pointAmount);
    event TotalPointsAllocated(
        uint256 indexed pointsTotal,
        uint256 indexed tokenPerPoint
    );
    event Referral(string indexed referral, uint256 indexed normalizedAmount);
    event RaiseWalletUpdated(address indexed oldWallet, address indexed newWallet);
    event ClaimsEnabled();
    event LaunchTimeSet(uint32 indexed launchTimestamp);
    event Distributed(address indexed account, uint256 indexed amount);
}