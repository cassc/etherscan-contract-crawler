// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./common/BaseTimelock.sol";

contract PresaleTimelock is BaseTimelock {
    using SafeERC20 for IERC20;
    using DateTime for uint256;

    uint256 public immutable cliffPeriodInMonth;
    uint256 public immutable vestingPeriodInMonth;

    event BeneficiaryChanged(address beneficiary, address nextBeneficiary);

    constructor(
        IERC20 _token,
        address _beneficiary,
        uint256 _totalAmount,
        uint256 _cliffPeriodInMonth,
        uint256 _vestingPeriodInMonth
    ) BaseTimelock(_token, _beneficiary, _totalAmount) {
        require(_cliffPeriodInMonth > 0, "invalid cliff period");
        require(_vestingPeriodInMonth > 0, "invalid vesting period");

        cliffPeriodInMonth = _cliffPeriodInMonth;
        vestingPeriodInMonth = _vestingPeriodInMonth;
    }

    function changeBeneficiary(address newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0), "beneficiary address cannot be zero");

        emit BeneficiaryChanged(beneficiary, newBeneficiary);
        beneficiary = newBeneficiary;
    }

    function unlockedAmountAt(uint256 timestamp) public view override returns (uint256) {
        if (start.addMonths(cliffPeriodInMonth) > timestamp) {
            // before the end of the cliff
            return 0;
        } else if (start.addMonths(cliffPeriodInMonth).addMonths(vestingPeriodInMonth) <= timestamp) {
            // after the end of the vesting
            return totalAmount;
        } else {
            // during vesting period
            uint256 diffMonth = _diffMonth(start.addMonths(cliffPeriodInMonth), timestamp);
            require(diffMonth <= vestingPeriodInMonth, "invalid diffmonth");
            return (totalAmount * diffMonth) / vestingPeriodInMonth;
        }
    }
}