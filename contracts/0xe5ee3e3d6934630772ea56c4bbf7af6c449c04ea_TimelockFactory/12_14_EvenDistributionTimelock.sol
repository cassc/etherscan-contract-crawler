// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./common/BaseTimelock.sol";

contract EvenDistributionTimelock is BaseTimelock {
    using DateTime for uint256;

    uint256 public immutable initialUnlockAmount;
    uint256 public immutable monthlyUnlockAmount;

    uint256 public immutable durationInMonth;

    constructor(
        IERC20 _token,
        address _beneficiary,
        uint256 _totalAmount,
        uint256 _initialUnlockAmount,
        uint256 _monthlyUnlockAmount,
        uint256 _durationInMonth
    ) BaseTimelock(_token, _beneficiary, _totalAmount) {
        require(
            _initialUnlockAmount + _monthlyUnlockAmount * _durationInMonth == _totalAmount,
            "invalid unlock amount"
        );
        require(_durationInMonth > 0, "invalid duration");

        initialUnlockAmount = _initialUnlockAmount;
        monthlyUnlockAmount = _monthlyUnlockAmount;
        durationInMonth = _durationInMonth;
    }

    function claim(uint256 amount) public override onlyBeneficiary {
        super.claim(amount);
    }

    function unlockedAmountAt(uint256 timestamp) public view override returns (uint256) {
        if (start > timestamp) {
            // initial unlock amount remains unlocked before the start
            return initialUnlockAmount;
        } else if (start.addMonths(durationInMonth) <= timestamp) {
            // total amount should be unlocked after the duration end
            return totalAmount;
        } else {
            uint256 diffMonth = _diffMonth(start, timestamp);
            require(diffMonth <= durationInMonth, "invalid diffmonth");
            return initialUnlockAmount + _diffMonth(start, timestamp) * monthlyUnlockAmount;
        }
    }
}