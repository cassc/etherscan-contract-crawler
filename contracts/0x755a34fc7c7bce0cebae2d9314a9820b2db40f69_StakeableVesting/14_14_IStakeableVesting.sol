// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStakeableVesting {
    event SetBeneficiary(address beneficiary);

    event WithdrawnAsBeneficiary(uint256 amount);

    event WithdrawnAsOwner(uint256 amount);

    function initialize(
        address _owner,
        address _beneficiary,
        uint32 startTimestamp,
        uint32 endTimestamp,
        uint192 amount
    ) external;

    function setBeneficiary(address _beneficiary) external;

    function withdrawAsOwner() external;

    function withdrawAsBeneficiary() external;

    function depositAtPool(uint256 amount) external;

    function withdrawAtPool(uint256 amount) external;

    function withdrawPrecalculatedAtPool(uint256 amount) external;

    function stakeAtPool(uint256 amount) external;

    function scheduleUnstakeAtPool(uint256 amount) external;

    function unstakeAtPool() external;

    function delegateAtPool(address delegate) external;

    function undelegateAtPool() external;

    function stateAtPool()
        external
        view
        returns (
            uint256 unstaked,
            uint256 staked,
            uint256 unstaking,
            uint256 unstakeScheduledFor,
            uint256 lockedStakingRewards,
            address delegate,
            uint256 lastDelegationUpdateTimestamp
        );

    function unvestedAmount() external view returns (uint256);

    function api3Token() external returns (address);

    function beneficiary() external returns (address);

    function vesting()
        external
        returns (uint32 startTimestamp, uint32 endTimestamp, uint192 amount);
}