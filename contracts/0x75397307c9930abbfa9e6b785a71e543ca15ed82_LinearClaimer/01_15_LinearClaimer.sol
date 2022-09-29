// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import './IClaimer.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './GeneralClaimer.sol';
import './WithDiamondHands.sol';

contract LinearClaimer is IClaimer, Ownable, GeneralClaimer, WithDiamondHands {
    struct Allocation {
        uint256 amount;
        // We find how much user currently has for unlock based on "amount - claimed"
        uint256 claimedAmount;
        uint256 lastClaimTimestamp;
    }

    // Unlock happens every N seconds: every second, hourly, daily...
    uint256 public unitOfTime = 1;
    // First unlock percent, with one decimal. 20% = 200. ZERO means no initial unlock
    uint256 public initialPercent;
    // First unlock date timestamp: e.g. 5 minutes after a listing. ZERO means no initial unlock
    uint256 public initialUnlockDate;
    // Vesting start date timestamp: e.g. 2 months (cliff) after the initial unlock
    uint256 public vestingStartDate;
    // Duration of the vesting in seconds: one week, few months, year
    uint256 public vestingDuration;

    mapping(address => Allocation) public allocations;

    event Claimed(address indexed account, uint256 amount, uint256 timestamp);
    event DuplicateAllocationSkipped(address indexed account, uint256 failedAllocation, uint256 existingAllocation);

    constructor(
        string memory _id,
        address _token,
        uint256 _unitOfTime,
        uint256 _initialPercent,
        uint256 _initialUnlockDate,
        uint256 _vestingStartDate,
        uint256 _vestingDuration
    ) {
        id = _id;
        token = _token;

        setUnitOfTime(_unitOfTime);
        setInitialPercent(_initialPercent);
        setInitialUnlockDate(_initialUnlockDate);
        setVestingStartDate(_vestingStartDate);
        setVestingDuration(_vestingDuration);
    }

    function setUnitOfTime(uint256 value) public onlyOwner {
        require(value >= 1, 'Unit of time must be >=1');
        unitOfTime = value;
    }

    function setInitialPercent(uint256 value) public onlyOwner {
        require(value < 1000, 'Initial unlock must be <100%');
        initialPercent = value;
    }

    function setInitialUnlockDate(uint256 value) public onlyOwner {
        initialUnlockDate = value;
    }

    function setVestingStartDate(uint256 value) public onlyOwner {
        require(value >= block.timestamp - 365 days, 'Vesting start must be within last year');
        require(value > initialUnlockDate, 'Vesting start must be after initial unlock');
        vestingStartDate = value;
    }

    function setVestingDuration(uint256 value) public onlyOwner {
        require(value >= 1 days, 'Vesting duration must be >=1 day');
        vestingDuration = value;
    }

    function claim(address account, uint256 idx) external override {
        // TODO: how to throw an error
        require(false, 'Not supported');
    }

    function claimAll(address account) external override {
        uint256 claimableAmount = getAccountClaimableAmount(account);
        require(claimableAmount > 0, 'Claimer: Nothing to claim');
        require(
            allocations[account].claimedAmount + claimableAmount <= allocations[account].amount,
            'Claimer: Claiming more than you have'
        );
        require(isAccountEligible(account), 'Claimer: Account is ineligible due to the Diamond Hands rule');

        transferTokens(account, claimableAmount);
        allocations[account].claimedAmount += claimableAmount;
        totalClaimedTokens += claimableAmount;

        emit Claimed(account, claimableAmount, block.timestamp);
    }

    function isClaimable(address account, uint256 claimIdx) external view override returns (bool) {
        // TODO: how to throw an error
        require(false, 'Not supported');
        return false;
    }

    function isClaimed(address account, uint256 claimIdx) external view override returns (bool) {
        // TODO: how to throw an error
        require(false, 'Not supported');
        return false;
    }

    function getTotalStats()
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (totalTokens, totalClaimedTokens, totalTokens - totalClaimedTokens);
    }

    function getAccountStats(address account)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (allocations[account].amount, allocations[account].claimedAmount, getAccountClaimableAmount(account));
    }

    function getAccountRemaining(address account) internal view override returns (uint256) {
        return allocations[account].amount - allocations[account].claimedAmount;
    }

    function setAllocation(address account, uint256 newTotal) external override onlyOwner {
        if (newTotal >= allocations[account].amount) {
            totalTokens += newTotal - allocations[account].amount;
        } else {
            totalTokens -= allocations[account].amount - newTotal;
        }
        allocations[account].amount = newTotal;
    }

    function batchAddAllocation(address[] calldata addresses, uint256[] calldata amounts) external override onlyOwner {
        batchAddAllocationWithClaimed(addresses, amounts, new uint256[][](0));
    }

    function batchAddAllocationWithClaimed(
        address[] calldata addresses,
        uint256[] calldata amounts,
        uint256[][] memory claimed
    ) public override onlyOwner {
        require(addresses.length == amounts.length, 'Claimer: Arguments length mismatch');

        for (uint256 i = 0; i < addresses.length; i++) {
            address account = addresses[i];
            uint256 alloc = amounts[i];

            // Skip already added users
            if (allocations[account].amount > 0) {
                emit DuplicateAllocationSkipped(account, alloc, allocations[account].amount);
                continue;
            }
    
            accounts.push(account);

            allocations[account].amount = alloc;
            totalTokens += alloc;

            if (claimed.length == addresses.length) {
                allocations[account].claimedAmount = claimed[i][0];
                totalClaimedTokens += claimed[i][0];
            }
        }
    }

    function getAccountClaimableAmount(address account) internal view returns (uint256) {
        uint256 unlockedAmount = getUnlockedAmount(allocations[account].amount);
        uint256 claimedAmount = allocations[account].claimedAmount;

        return unlockedAmount > claimedAmount ? unlockedAmount - claimedAmount : 0;
    }

    function getUnlockedAmount(uint256 amount) internal view returns (uint256) {
        uint256 timestamp = isPaused() ? pausedAt : block.timestamp;

        if (timestamp >= vestingStartDate + vestingDuration) {
            return amount;
        }

        uint256 unlockedAmount = 0;
        uint256 initialAmount = (amount * initialPercent) / 1000;
        uint256 tokensPerUnlock = (amount - initialAmount) / getTotalUnlocksN();

        if (timestamp > initialUnlockDate) {
            unlockedAmount += initialAmount;
        }
        if (timestamp >= vestingStartDate) {
            unlockedAmount += getUnlockedVestingLocksN() * tokensPerUnlock;
        }

        return unlockedAmount <= amount ? unlockedAmount : amount;
    }

    function getTotalUnlocksN() internal view returns (uint256) {
        uint256 totalN = vestingDuration / unitOfTime;
        return totalN > 0 ? totalN : 1;
    }

    function getUnlockedVestingLocksN() internal view returns (uint256) {
        uint256 timestamp = isPaused() ? pausedAt : block.timestamp;

        if (timestamp < vestingStartDate) {
            return 0;
        }
        // Once we're past the vestingStartDate, there's always one unlock available immediately.
        // Next is unlocked when "unitOfTime" seconds have passed since "vestingStartDate".
        uint256 unlockedN = 1 + (timestamp - vestingStartDate) / unitOfTime;
        uint256 totalN = getTotalUnlocksN();
        return unlockedN <= totalN ? unlockedN : totalN;
    }

    function transferAllocation(address from, address to) external override onlyOwner {
        require(allocations[from].amount > 0, 'User has no allocation');
        require(allocations[to].amount == 0, "Can't transfer to an address with existing allocation");
        require(transferredAccountsMap[from] == address(0), 'User has already been transferred');
        require(transferredAccountsMap[to] == address(0), "Can't transfer to an address that has been transferred");

        accounts.push(to);

        transferredAccountsMap[from] = to;
        transferredAccounts.push([from, to]);

        allocations[to].amount = allocations[from].amount;
        allocations[to].claimedAmount = allocations[from].claimedAmount;
        allocations[to].lastClaimTimestamp = allocations[from].lastClaimTimestamp;
        allocations[from].amount = 0;
        allocations[from].claimedAmount = 0;
        allocations[from].lastClaimTimestamp = 0;

        emit AllocationTransferred(from, to);
    }
}