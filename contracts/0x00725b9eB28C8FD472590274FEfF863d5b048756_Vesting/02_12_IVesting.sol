// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

interface IVesting {
    /**
     * @notice Emits when a new vesting rule has been added
     */
    event VestingAdded(
        address indexed account,
        uint256 amount,
        uint256 strartTime,
        uint256 endTime
    );

    /**
     * @notice Emits when vesting is released in full or partially
     */
    event VestingReleased(
        address indexed account,
        uint256 vestingSet,
        uint256 amount,
        uint256 time
    );

    struct Vest {
        uint256 totalAmount; // Total amount to be paid
        uint256 paidAmount; // Paid amount
        uint256 strartTime; // From what time vesting should start (unix time)
        uint256 endTime;
    }

    struct Payment {
        uint256 vestingSet; // Key of _vested array
        uint256 amount;
        uint256 time;
    }

    function addVesting(
        address _account,
        uint256 _amount,
        uint256 _strartTime,
        uint256 _endTime
    ) external returns (bool);
    
    function releasableAmount(address _account, uint16 _vestingSet) external view returns (uint256);

    function release(address _account, uint16 _vestingSet, uint256 _amount) external returns (bool);

    function vestingPlan(address _account) external view returns (Vest[] memory);

    function payouts(address _account) external view returns (Payment[] memory);

    function vestingAccountsTotal() external view returns (uint256);

    function vestingAccountsGet(uint256 _start, uint256 _size) external view returns (address[] memory);

}