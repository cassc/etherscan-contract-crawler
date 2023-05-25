// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ITokenLocker {
    struct Lock {
        uint192 amount;
        uint32 lockedAt;
        uint32 lockDuration;
    }

    // State changing methods
    function depositByMonths(uint192 _amount, uint256 _months, address _receiver) external;
    function boostToMax() external;
    function increaseAmount(uint192 _amount) external;
    function increaseByMonths(uint256 _months) external;
    function migrate(address staker) external;

    /**
     * @notice Ejects a list of lock accounts from the contract.
     * @dev    Smart contracts with locked rewardToken balances should be mindful that
     *         they may be ejected from the contract by external users.
     */
    function eject(address[] calldata _lockAccounts) external;

    // View methods
    function getLock(address _depositor) external returns (Lock memory);
    function lockOf(address account) external view returns (uint192, uint32, uint32);
    function minLockAmount() external returns (uint256);
    function maxLockDuration() external returns (uint32);
    function getLockMultiplier(uint32 _duration) external view returns (uint256);
    function getSecondsMonths() external view returns (uint256);
    function previewDepositByMonths(uint192 _amount, uint256 _months, address _receiver) external view returns (uint256);
    function whitelisted(address _reciever) external returns (bool);
}