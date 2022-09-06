// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMembershipStaking {
    function managerMinimalStake() external view returns (uint256);

    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256);

    function lockStake(address account) external returns (uint256);

    function unlockAndWithdrawStake(
        address staker,
        address receiver,
        uint256 amount
    ) external;

    function burnStake(address account, uint256 amount) external;
}