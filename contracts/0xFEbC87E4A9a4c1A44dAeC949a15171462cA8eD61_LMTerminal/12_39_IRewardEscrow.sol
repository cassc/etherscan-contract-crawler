// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IRewardEscrow {
    function MAX_VESTING_ENTRIES() external view returns (uint256);

    function addRewardsContract(address _rewardContract) external;

    function appendVestingEntry(
        address token,
        address account,
        address pool,
        uint256 quantity
    ) external;

    function balanceOf(address token, address account)
        external
        view
        returns (uint256);

    function checkAccountSchedule(
        address pool,
        address token,
        address account
    ) external view returns (uint256[] memory);

    function clrPoolVestingPeriod(address) external view returns (uint256);

    function getNextVestingEntry(
        address pool,
        address token,
        address account
    ) external view returns (uint256[2] memory);

    function getNextVestingIndex(
        address pool,
        address token,
        address account
    ) external view returns (uint256);

    function getNextVestingQuantity(
        address pool,
        address token,
        address account
    ) external view returns (uint256);

    function getNextVestingTime(
        address pool,
        address token,
        address account
    ) external view returns (uint256);

    function getVestingQuantity(
        address pool,
        address token,
        address account,
        uint256 index
    ) external view returns (uint256);

    function getVestingScheduleEntry(
        address pool,
        address token,
        address account,
        uint256 index
    ) external view returns (uint256[2] memory);

    function getVestingTime(
        address pool,
        address token,
        address account,
        uint256 index
    ) external view returns (uint256);

    function initialize() external;

    function isRewardContract(address) external view returns (bool);

    function numVestingEntries(
        address pool,
        address token,
        address account
    ) external view returns (uint256);

    function owner() external view returns (address);

    function removeRewardsContract(address _rewardContract) external;

    function renounceOwnership() external;

    function setCLRPoolVestingPeriod(address pool, uint256 vestingPeriod)
        external;

    function totalEscrowedAccountBalance(address, address)
        external
        view
        returns (uint256);

    function totalEscrowedBalance(address) external view returns (uint256);

    function totalSupply(address token) external view returns (uint256);

    function totalVestedAccountBalance(address, address)
        external
        view
        returns (uint256);

    function transferOwnership(address newOwner) external;

    function vest(address pool, address token) external;

    function vestAll(address pool, address[] memory tokens) external;

    function vestingSchedules(
        address,
        address,
        address,
        uint256,
        uint256
    ) external view returns (uint256);
}