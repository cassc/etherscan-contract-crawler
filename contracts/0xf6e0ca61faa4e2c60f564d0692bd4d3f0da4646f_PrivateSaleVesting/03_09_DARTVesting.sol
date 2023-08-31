// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../DARTToken.sol";

contract DARTVesting is Context, Ownable {
    using SafeMath for uint256;

    struct VestingSchedule {
        uint256 totalAmount; // Total amount of tokens to be vested.
        uint256 amountWithdrawn; // The amount that has been withdrawn.
    }

    mapping(address => VestingSchedule) public recipients;
    address[] recipientAddresses;

    uint256 public startTime;
    bool public isStartTimeSet;
    uint256 public withdrawInterval = 1 days; // Amount of time in seconds between withdrawal periods.
    uint256 public releasePeriods; // Number of periods from start release until done.
    uint256 public lockPeriods; // Number of periods before start release.

    uint256 public unlockTGEPercent;

    uint256 public totalAmount; // Total amount of tokens to be vested.
    uint256 public unallocatedAmount; // The amount of tokens that are not allocated yet.

    bool initialDistributed = false;

    DARTToken public dARTToken;

    event VestingScheduleRegistered(
        address[] registeredAddresses,
        uint256[] allocations
    );
    event Withdraw(address registeredAddress, uint256 amountWithdrawn);
    event StartTimeSet(uint256 startTime);

    constructor(
        DARTToken _dARTToken,
        uint256 _totalAmount,
        uint256 _releasePeriods,
        uint256 _lockPeriods,
        uint256 _unlockTGEPercent
    ) {
        require(_totalAmount > 0, "Total amount should not be zero");
        require(_releasePeriods > 0, "Release periods should not be zero");

        dARTToken = _dARTToken;

        totalAmount = _totalAmount;
        unallocatedAmount = _totalAmount;
        releasePeriods = _releasePeriods;
        lockPeriods = _lockPeriods;
        unlockTGEPercent = _unlockTGEPercent;
    }

    function addRecipients(address[] memory _newRecipients, uint256[] memory _allocations)
        external
        onlyOwner
    {
        // Only allow to add recipient before the counting starts
        require(!isStartTimeSet || startTime > block.timestamp, "Start time is passed");
        require(_newRecipients.length == _allocations.length, "Recipients length should match allocations length");

        uint256 length = _allocations.length;

        for (uint256 i = 0; i < length; i ++) {
            require(_newRecipients[i] != address(0), "Recipient cannot be zero address");
            require(recipients[_newRecipients[i]].totalAmount == 0, "Recipient already added");
            require(_allocations[i] > 0 && _allocations[i] <= unallocatedAmount, "Allocation cannot be zero and cannot override unallocated amount");

            recipientAddresses.push(_newRecipients[i]);

            recipients[_newRecipients[i]] = VestingSchedule({
                totalAmount: _allocations[i],
                amountWithdrawn: 0
            });

            unallocatedAmount = unallocatedAmount.sub(_allocations[i]);
        }

        emit VestingScheduleRegistered(_newRecipients, _allocations);
    }

    function setStartTime(uint256 _newStartTime) external onlyOwner {
        // Only allow to change start time before the counting starts
        require(!isStartTimeSet || startTime > block.timestamp, "Start time already passed");
        require(_newStartTime > block.timestamp, "Start time should be later than now");

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
            (lockPeriods == 0 && releasePeriods == 0) ||
            (block.timestamp < startTime)
        ) {
            return 0;
        }

        uint256 period =
            block.timestamp.sub(startTime).div(withdrawInterval);
        if (period <= lockPeriods) {
            return 0;
        }
        if (period >= lockPeriods.add(releasePeriods)) {
            return _vestingSchedule.totalAmount;
        }

        uint256 vestedAmount = _vestingSchedule.totalAmount.mul(period.sub(lockPeriods)).div(releasePeriods);
        return vestedAmount;
    }

    function withdrawable(address beneficiary)
        public
        view
        returns (uint256 amount)
    {
        return vested(beneficiary).sub(recipients[beneficiary].amountWithdrawn);
    }

    function withdraw() external {
        VestingSchedule storage vestingSchedule = recipients[_msgSender()];
        require(vestingSchedule.totalAmount > 0, "No Tokens to withdraw");

        uint256 _vested = vested(msg.sender);
        uint256 _withdrawable = withdrawable(msg.sender);
        vestingSchedule.amountWithdrawn = _vested;

        if (_withdrawable > 0) {
            require(dARTToken.transfer(_msgSender(), _withdrawable), "Transfer failed for some reason");
            emit Withdraw(_msgSender(), _withdrawable);
        }
    }

    function distributeInitials() external onlyOwner() {
        require(!initialDistributed, "Already distributed");

        initialDistributed = true;

        uint256 recipientLength = recipientAddresses.length;
        
        for (uint i = 0; i < recipientLength; i ++) {
            address recipientAddr = recipientAddresses[i];
            if (recipients[recipientAddr].totalAmount > 0) {
                uint256 amount = recipients[recipientAddr].totalAmount.mul(unlockTGEPercent).div(100);
                recipients[recipientAddr].totalAmount = recipients[recipientAddr].totalAmount.sub(amount);
                dARTToken.transfer(recipientAddr, amount);
            }
        }
    }
}