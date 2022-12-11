// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IDibs {
    function getActiveLotteryRound() external view returns (uint32);

    function roundDuration() external view returns (uint32);

    function firstRoundStartTime() external view returns (uint32);

    function roundToWinner(uint32) external view returns (address);

    function claim(
        address from,
        address token,
        uint256 amount,
        address to,
        uint256 accumulativeBalance
    ) external;

    function setRoundWinner(uint32 roundId, address winner) external;
}