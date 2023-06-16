// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVesting is Pausable, Ownable {
    using SafeMath for uint256;

    struct VestingSchedule {
        uint256 totalAmount; // Total amount of tokens to be vested.
        uint256 amountWithdrawn; // The amount that has been withdrawn.
    }

    mapping(address => VestingSchedule) public recipients;

    uint256 public startTime;
    bool public isStartTimeSet;
    bool public isPaused;
    uint256 public withdrawInterval; // Amount of time in seconds between withdrawal periods.
    uint256 public releaseRate; // Release percent in each withdrawing interval

    uint256 public totalAmount; // Total amount of tokens to be vested.
    uint256 public unallocatedAmount; // The amount of tokens that are not allocated yet.
    uint256 public initialUnlock; // Percent of tokens initially unlocked
    uint256 public lockPeriod; // Number of periods before start release.

    IERC20 public formToken;

    event VestingScheduleRegistered(
        address registeredAddress,
        uint256 totalAmount
    );
    event VestingSchedulesRegistered(
        address[] registeredAddresses,
        uint256[] totalAmounts
    );
    event Withdraw(address registeredAddress, uint256 amountWithdrawn);
    event StartTimeSet(uint256 startTime);

    constructor(
        address _formToken,
        uint256 _totalAmount,
        uint256 _initialUnlock,
        uint256 _withdrawInterval,
        uint256 _releaseRate,
        uint256 _lockPeriod
    ) public {
        formToken = IERC20(_formToken);

        totalAmount = _totalAmount;
        initialUnlock = _initialUnlock;
        unallocatedAmount = _totalAmount;
        withdrawInterval = _withdrawInterval;
        releaseRate = _releaseRate;
        lockPeriod = _lockPeriod;
    }

    function addRecipient(address _newRecipient, uint256 _totalAmount)
        external
        onlyOwner
    {
        // Only allow to add recipient before the counting starts
        require(!isStartTimeSet || startTime > block.timestamp);
        require(_newRecipient != address(0));
        require(recipients[_newRecipient].totalAmount == 0);

        unallocatedAmount = unallocatedAmount.add(
            recipients[_newRecipient].totalAmount
        );
        require(_totalAmount > 0 && _totalAmount <= unallocatedAmount);

        recipients[_newRecipient] = VestingSchedule({
            totalAmount: _totalAmount,
            amountWithdrawn: 0
        });
        unallocatedAmount = unallocatedAmount.sub(_totalAmount);

        emit VestingScheduleRegistered(_newRecipient, _totalAmount);
    }

    function addRecipients(
        address[] memory _newRecipients,
        uint256[] memory _totalAmounts
    ) external onlyOwner {
        // Only allow to add recipient before the counting starts
        require(!isStartTimeSet || startTime > block.timestamp);

        for (uint256 i = 0; i < _newRecipients.length; i++) {
            address _newRecipient = _newRecipients[i];
            uint256 _totalAmount = _totalAmounts[i];

            require(_newRecipient != address(0));
            require(recipients[_newRecipient].totalAmount == 0);

            unallocatedAmount = unallocatedAmount.add(
                recipients[_newRecipient].totalAmount
            );
            require(_totalAmount > 0 && _totalAmount <= unallocatedAmount);

            recipients[_newRecipient] = VestingSchedule({
                totalAmount: _totalAmount,
                amountWithdrawn: 0
            });
            unallocatedAmount = unallocatedAmount.sub(_totalAmount);
        }

        emit VestingSchedulesRegistered(_newRecipients, _totalAmounts);
    }

    function setStartTime(uint256 _newStartTime) external onlyOwner {
        // Only allow to change start time before the counting starts
        require(!isStartTimeSet || startTime > block.timestamp);
        require(_newStartTime > block.timestamp);

        startTime = _newStartTime;
        isStartTimeSet = true;

        emit StartTimeSet(_newStartTime);
    }

    // Returns the amount of tokens you can withdraw
    function vested(address beneficiary)
        public
        view
        virtual
        returns (uint256 _amountVested)
    {
        VestingSchedule memory _vestingSchedule = recipients[beneficiary];
        if (
            !isStartTimeSet ||
            (_vestingSchedule.totalAmount == 0) ||
            (block.timestamp < startTime) ||
            (block.timestamp < startTime.add(lockPeriod))
        ) {
            return 0;
        }

        uint256 initialUnlockAmount =
            _vestingSchedule.totalAmount.mul(initialUnlock).div(1e6);

        uint256 unlockRate =
            _vestingSchedule.totalAmount.mul(releaseRate).div(1e6).div(
                withdrawInterval
            );

        uint256 vestedAmount =
            unlockRate.mul(block.timestamp.sub(startTime).sub(lockPeriod)).add(
                initialUnlockAmount
            );

        if (vestedAmount > _vestingSchedule.totalAmount) {
            return _vestingSchedule.totalAmount;
        }
        return vestedAmount;
    }

    function locked(address beneficiary) public view returns (uint256) {
        return recipients[beneficiary].totalAmount.sub(vested(beneficiary));
    }

    function withdrawable(address beneficiary)
        public
        view
        returns (uint256 amount)
    {
        return vested(beneficiary).sub(recipients[beneficiary].amountWithdrawn);
    }

    function emergencyWithdraw(uint256 _amount) 
        external 
        onlyOwner
    {
        require(_amount > 0, "Nothing to withdraw");
        require(_amount <= formToken.balanceOf(address(this)), "Amount to withdraw exceeds balance");
        require(formToken.transfer(_msgSender(), _amount));

        emit Withdraw(_msgSender(), _amount);
    }

    function withdraw() external whenNotPaused {
        VestingSchedule storage vestingSchedule = recipients[_msgSender()];
        if (vestingSchedule.totalAmount == 0) return;

        uint256 _vested = vested(_msgSender());
        uint256 _withdrawable = withdrawable(_msgSender());
        vestingSchedule.amountWithdrawn = _vested;

        require(_withdrawable > 0, "Nothing to withdraw");
        require(formToken.transfer(_msgSender(), _withdrawable));
        emit Withdraw(_msgSender(), _withdrawable);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}