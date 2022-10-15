// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILockableStaking {
    function createLock(
        address user,
        uint256 index,
        uint32 until,
        uint256 amount
    ) external;

    function deleteExpiredLock(address user, uint256 index) external;
}

interface IRefTreeStorage {
    function refererOf(address user) external view returns (address);

    function referralsOf(address referer) external view returns (address[] memory);

    function setReferer(address user, address referer) external;
}

interface ITicketsCounter {
    struct StakingLockDetails {
        uint256 amount;
        ILockableStaking target;
    }

    function smartLockTickets(
        address user,
        uint256 drawDate,
        uint256 ticketsRequested
    ) external returns (StakingLockDetails[] memory shouldLock);

    function countTickets(address user, uint256 drawDate)
        external
        view
        returns (uint256 totalTickets, uint256 usableTickets);

    function unlockTickets(address user, uint256 amount) external;
}

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}