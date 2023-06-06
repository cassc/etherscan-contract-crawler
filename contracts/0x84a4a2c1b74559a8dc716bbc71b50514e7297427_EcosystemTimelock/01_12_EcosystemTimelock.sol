// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./common/BaseTimelockUpgradeable.sol";

contract EcosystemTimelock is BaseTimelockUpgradeable {
    using DateTime for uint256;

    uint256 public unlockAmount;

    uint256 public halfLifeInMonth;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IERC20 _token,
        address _beneficiary,
        uint256 _totalAmount,
        uint256 _unlockAmount,
        uint256 _halfLifeInMonth
    ) external initializer {
        __BaseTimelock_init(_token, _beneficiary, _totalAmount);

        require(_unlockAmount * _halfLifeInMonth * 2 < _totalAmount, "invalid unlock amount");
        require(_halfLifeInMonth > 0, "invalid halflife");
        unlockAmount = _unlockAmount;
        halfLifeInMonth = _halfLifeInMonth;
    }

    function claim(uint256 amount) public override onlyBeneficiary {
        super.claim(amount);
    }

    function unlockedAmountAt(uint256 timestamp) public view override returns (uint256) {
        if (start > timestamp) {
            return 0;
        } else {
            uint256 diffMonth = _diffMonth(start, timestamp);
            uint256 n = diffMonth / halfLifeInMonth;
            // reciprocal of ratio
            uint256 t = 2;
            uint256 sum = 0;
            if (n > 0) {
                // sum of geometric sequences
                sum = (unlockAmount * halfLifeInMonth * t - (unlockAmount * halfLifeInMonth) / t ** (n - 1)) / (t - 1);
            }

            return sum + ((unlockAmount * (diffMonth % halfLifeInMonth)) / 2 ** n);
        }
    }
}