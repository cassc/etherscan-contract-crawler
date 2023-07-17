// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

interface ITORUSVoteLocker {
    event Locked(address indexed account, uint256 amount, uint256 unlockTime, bool relocked);
    event UnlockExecuted(address indexed account, uint256 amount);

    function lock(uint256 amount) external;

    function lock(uint256 amount, bool relock) external;

    function shutDown() external;

    function recoverToken(address token) external;

    function executeAvailableUnlocks() external returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function unlockableBalance(address user) external view returns (uint256);
}