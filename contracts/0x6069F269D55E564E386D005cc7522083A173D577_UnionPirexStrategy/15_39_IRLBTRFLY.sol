// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRLBTRFLY {
    struct LockedBalance {
        uint224 amount;
        uint32 unlockTime;
    }

    function lock(address account, uint256 amount) external;

    function lockedBalances(address account)
        external
        view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        );

    function lockedBalanceOf(address account)
        external
        view
        returns (uint256 amount);

    function processExpiredLocks(bool relock) external;

    function shutdown() external;
}