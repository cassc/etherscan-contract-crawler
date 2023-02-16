// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICakePool {
    function totalShares() external view returns (uint256);

    struct UserInfo {
        uint256 shares; // number of shares for a user.
        uint256 lastDepositedTime; // keep track of deposited time for potential penalty.
        uint256 cakeAtLastUserAction; // keep track of cake deposited at the last user action.
        uint256 lastUserActionTime; // keep track of the last user action time.
        uint256 lockStartTime; // lock start time.
        uint256 lockEndTime; // lock end time.
        uint256 userBoostedShare; // boost share, in order to give the user higher reward. The user only enjoys the reward, so the principal needs to be recorded as a debt.
        bool locked; //lock status.
        uint256 lockedAmount; // amount deposited during lock period.
    }

    function withdrawFeePeriod() external view returns (uint256);

    function freeWithdrawFeeUsers(address user_) external view returns (bool);

    function MAX_LOCK_DURATION() external view returns (uint256);

    function userInfo(address user_) external view returns (UserInfo memory);

    function deposit(uint256 _amount, uint256 _lockDuration) external;

    function withdrawByAmount(uint256 _amount) external;

    /**
     * @notice Calculate Performance fee.
     * @param _user: User address
     * @return Returns Performance fee.
     */
    function calculatePerformanceFee(address _user) external view returns (uint256);

    function calculateWithdrawFee(address _user, uint256 _shares) external view returns (uint256);

    function calculateOverdueFee(address _user) external view returns (uint256);

    /**
     * @notice Withdraw funds from the Cake Pool.
     * @param _shares: Number of shares to withdraw
     */
    function withdraw(uint256 _shares) external;

    function withdrawAll() external;

    function getPricePerFullShare() external view returns (uint256);
}