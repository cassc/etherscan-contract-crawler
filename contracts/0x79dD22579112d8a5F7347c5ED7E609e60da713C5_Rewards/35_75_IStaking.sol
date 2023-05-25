// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface IStaking {

    struct StakingSchedule {
        uint256 cliff; // Duration in seconds before staking starts
        uint256 duration; // Seconds it takes for entire amount to stake
        uint256 interval; // Seconds it takes for a chunk to stake
        bool setup; //Just so we know its there        
        bool isActive; //Whether we can setup new stakes with the schedule
        uint256 hardStart; //Stakings will always start at this timestamp if set    
        bool isPublic; //Schedule can be written to by any account    
    }

    struct StakingScheduleInfo {
        StakingSchedule schedule;
        uint256 index;
    }

    struct StakingDetails {
        uint256 initial; //Initial amount of asset when stake was created, total amount to be staked before slashing
        uint256 withdrawn; //Amount that was staked and subsequently withdrawn
        uint256 slashed; //Amount that has been slashed        
        uint256 started; //Timestamp at which the stake started
        uint256 scheduleIx;
    }

    struct WithdrawalInfo {
        uint256 minCycleIndex;
        uint256 amount;
    }

    event ScheduleAdded(uint256 scheduleIndex, uint256 cliff, uint256 duration, uint256 interval, bool setup, bool isActive, uint256 hardStart);    
    event ScheduleRemoved(uint256 scheduleIndex);    
    event WithdrawalRequested(address account, uint256 amount);
    event WithdrawCompleted(address account, uint256 amount);    
    event Deposited(address account, uint256 amount, uint256 scheduleIx);
    event Slashed(address account, uint256 amount, uint256 scheduleIx);

    function permissionedDepositors(address account) external returns (bool);

    function setUserSchedules(address account, uint256[] calldata userSchedulesIdxs) external;

    function addSchedule(StakingSchedule memory schedule) external;

    function getSchedules() external view returns (StakingScheduleInfo[] memory);

    function setPermissionedDepositor(address account, bool canDeposit) external;

    function removeSchedule(uint256 scheduleIndex) external;    

    function getStakes(address account) external view returns(StakingDetails[] memory);

    function balanceOf(address account) external view returns(uint256);

    function availableForWithdrawal(address account, uint256 scheduleIndex) external view returns (uint256);

    function unvested(address account, uint256 scheduleIndex) external view returns(uint256);

    function vested(address account, uint256 scheduleIndex) external view returns(uint256);

    function deposit(uint256 amount, uint256 scheduleIndex) external;

    function depositFor(address account, uint256 amount, uint256 scheduleIndex) external;

    function depositWithSchedule(address account, uint256 amount, StakingSchedule calldata schedule) external;

    function requestWithdrawal(uint256 amount) external;

    function withdraw(uint256 amount) external;

    /// @notice Pause deposits on the pool. Withdraws still allowed
    function pause() external;

    /// @notice Unpause deposits on the pool.
    function unpause() external;
}