// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBoldCryptoLock {
    function lock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 unlockDate,
        string memory description
    ) external returns (uint256 lockId);

    function vestingLock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 tgeDate, // first release date
        bool useBatchRelease, // true for batch, false for linear
        uint256 vestingDuration,
        uint256 tgeBps, //first release percentage
        uint256 cycleBps, // each cycle percentage
        string memory description
    ) external returns (uint256 lockId);

    function multipleVestingLock(
        address[] calldata owners,
        uint256[] calldata amounts,
        address token,
        bool isLpToken,
        uint256 tgeDate,
        bool useBatchRelease,
        uint256 vestingDuration,
        uint256 tgeBps,
        uint256 cycleBps,
        string memory description
    ) external returns (uint256[] memory);

    function unlock(uint256 lockId) external;

    function editLock(
        uint256 lockId,
        uint256 newAmount,
        uint256 newUnlockDate
    ) external;
}
