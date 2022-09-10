// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './IClaimer.sol';
import './WithDiamondHands.sol';

contract Claimer is IClaimer, Ownable, GeneralClaimer, WithDiamondHands {
    struct Claim {
        uint256 unlockTime; // unix time
        uint256 percent; // three decimals: 1.783% = 1783
    }

    Claim[] public claims;

    mapping(address => uint256) public allocation;
    mapping(address => uint256) private claimedTotal;
    mapping(address => mapping(uint256 => uint256)) public userClaimedPerClaim;
    // Marks the indexes of claims already claimed by all participants, usually when it was airdropped
    uint256[] public alreadyDistributedClaims;

    event Claimed(address indexed account, uint256 amount, uint256 percent, uint256 claimIdx);
    event ClaimedMultiple(address indexed account, uint256 amount);
    event DuplicateAllocationSkipped(address indexed account, uint256 failedAllocation, uint256 existingAllocation);
    event ClaimReleased(uint256 percent, uint256 newTime, uint256 claimIdx);
    event ClaimTimeChanged(uint256 percent, uint256 newTime, uint256 claimIdx);
    event ClaimingPaused(bool status);

    constructor(
        string memory _id,
        address _token,
        uint256[] memory times,
        uint256[] memory percents
    ) {
        token = _token;
        id = _id;

        uint256 totalPercent;
        for (uint256 i = 0; i < times.length; i++) {
            require(percents[i] > 0, 'Claimer: 0% is not allowed');
            claims.push(Claim(times[i], percents[i]));
            totalPercent += percents[i];
        }
        require(totalPercent == 100000, 'Claimer: Sum of all claimed must be 100%');
    }

    function setAlreadyDistributedClaims(uint256[] calldata claimedIdx) external onlyOwner {
        for (uint256 i = 0; i < claimedIdx.length; i++) {
            require(claimedIdx[i] < claims.length, 'Claimer: Index out of bounds');
        }
        alreadyDistributedClaims = claimedIdx;
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
        uint256 claimed = totalClaimedTokens + getAlreadyDistributedAmount(totalTokens);
        uint256 remaining = totalTokens - claimed;
        return (totalTokens, claimed, remaining);
    }

    function getAccountStats(address account)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 claimable;
        for (uint256 i = 0; i < claims.length; i++) {
            if (isClaimable(account, i)) {
                claimable += getClaimAmount(allocation[account], i);
            }
        }
        uint256 claimed = claimedTotal[account] + getAlreadyDistributedAmount(allocation[account]);

        return (allocation[account], claimed, claimable);
    }

    function getAccountRemaining(address account) internal view override returns (uint256) {
        uint256 claimed = claimedTotal[account] + getAlreadyDistributedAmount(allocation[account]);
        if (claimed >= allocation[account]) {
            return 0;
        }
        return allocation[account] - claimed;
    }

    function getClaims(address account)
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            bool[] memory,
            uint256[] memory
        )
    {
        uint256 len = claims.length;
        uint256[] memory times = new uint256[](len);
        uint256[] memory percents = new uint256[](len);
        uint256[] memory amount = new uint256[](len);
        bool[] memory _isClaimable = new bool[](len);
        uint256[] memory claimedAmount = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            times[i] = claims[i].unlockTime;
            percents[i] = claims[i].percent;
            amount[i] = getClaimAmount(allocation[account], i);
            _isClaimable[i] = isClaimable(account, i);
            claimedAmount[i] = getAccountClaimed(account, i);
        }

        return (times, percents, amount, _isClaimable, claimedAmount);
    }

    function getAccountClaimed(address account, uint256 claimIdx) public view returns (uint256) {
        for (uint256 i = 0; i < alreadyDistributedClaims.length; i++) {
            if (alreadyDistributedClaims[i] == claimIdx) {
                return getClaimAmount(allocation[account], alreadyDistributedClaims[i]);
            }
        }

        return userClaimedPerClaim[account][claimIdx];
    }

    function getAlreadyDistributedAmount(uint256 total) public view returns (uint256) {
        uint256 amount;

        for (uint256 i = 0; i < alreadyDistributedClaims.length; i++) {
            amount += getClaimAmount(total, alreadyDistributedClaims[i]);
        }

        return amount;
    }

    function claim(address account, uint256 idx) external override {
        require(idx < claims.length, 'Claimer: Index out of bounds');
        require(allocation[account] > 0, "Claimer: Account doesn't have allocation");
        require(!isPaused(), 'Claimer: Claiming paused');
        require(isAccountEligible(account), 'Claimer: Account is ineligible due to the Diamond Hands rule');

        uint256 claimAmount = claimInternal(account, idx);
        transferTokens(account, claimAmount);
        emit Claimed(account, claimAmount, claims[idx].percent, idx);
    }

    function claimAll(address account) external override {
        require(allocation[account] > 0, "Claimer: Account doesn't have allocation");
        require(!isPaused(), 'Claimer: Claiming paused');
        require(isAccountEligible(account), 'Claimer: Account is ineligible due to the Diamond Hands rule');

        uint256 claimAmount = 0;
        for (uint256 idx = 0; idx < claims.length; idx++) {
            if (isClaimable(account, idx)) {
                claimAmount += claimInternal(account, idx);
            }
        }

        transferTokens(account, claimAmount);
        emit ClaimedMultiple(account, claimAmount);
    }

    function claimInternal(address account, uint256 idx) internal returns (uint256) {
        require(isClaimable(account, idx), 'Claimer: Not claimable or already claimed');

        uint256 claimAmount = getClaimAmount(allocation[account], idx);
        require(claimAmount > 0, 'Claimer: Amount is zero');

        totalClaimedTokens += claimAmount;
        claimedTotal[account] += claimAmount;
        userClaimedPerClaim[account][idx] = claimAmount;

        return claimAmount;
    }

    function setClaimTime(uint256 claimIdx, uint256 newUnlockTime) external onlyOwner {
        require(claimIdx < claims.length, 'Claimer: Index out of bounds');
        Claim storage _claim = claims[claimIdx];

        _claim.unlockTime = newUnlockTime;
        emit ClaimTimeChanged(_claim.percent, _claim.unlockTime, claimIdx);
    }

    function releaseClaim(uint256 claimIdx) external onlyOwner {
        require(claimIdx < claims.length, 'Claimer: Index out of bounds');
        Claim storage _claim = claims[claimIdx];

        require(_claim.unlockTime > block.timestamp, 'Claimer: Claim already released');
        _claim.unlockTime = block.timestamp;
        emit ClaimReleased(_claim.percent, _claim.unlockTime, claimIdx);
    }

    function isClaimable(address account, uint256 claimIdx) public view override returns (bool) {
        // The claim is already claimed by the user
        if (isClaimed(account, claimIdx)) {
            return false;
        }

        uint256 unlockTime = claims[claimIdx].unlockTime;
        // A claim without a specified time is TBC and cannot be claimed
        if (unlockTime == 0) {
            return false;
        }

        return isAccountEligible(account) && unlockTime < block.timestamp;
    }

    function isClaimed(address account, uint256 claimIdx) public view override returns (bool) {
        return userClaimedPerClaim[account][claimIdx] > 0 || isAlreadyDistributed(claimIdx);
    }

    function isAlreadyDistributed(uint256 claimIdx) public view returns (bool) {
        for (uint256 i = 0; i < alreadyDistributedClaims.length; i++) {
            if (alreadyDistributedClaims[i] == claimIdx) {
                return true;
            }
        }

        return false;
    }

    function getClaimAmount(uint256 total, uint256 claimIdx) internal view returns (uint256) {
        return (total * claims[claimIdx].percent) / 100000;
    }

    function setAllocation(address account, uint256 newTotal) external override onlyOwner {
        if (newTotal > allocation[account]) {
            totalTokens += newTotal - allocation[account];
        } else {
            totalTokens -= allocation[account] - newTotal;
        }
        allocation[account] = newTotal;
    }

    function batchAddAllocation(address[] calldata addresses, uint256[] calldata allocations)
        external
        override
        onlyOwner
    {
        require(addresses.length == allocations.length, 'Claimer: Arguments length mismatch');

        for (uint256 i = 0; i < addresses.length; i++) {
            address account = addresses[i];
            uint256 alloc = allocations[i];

            // Skip already added users
            if (allocation[account] > 0) {
                emit DuplicateAllocationSkipped(account, alloc, allocation[account]);
                continue;
            }

            allocation[account] = alloc;
            totalTokens += alloc;
            accounts.push(account);
        }
    }

    function batchAddAllocationWithClaimed(
        address[] calldata addresses,
        uint256[] calldata allocations,
        uint256[][] calldata claimed
    ) external override onlyOwner {
        require(addresses.length == allocations.length, 'Claimer: Arguments length mismatch');
        require(addresses.length == claimed.length, 'Claimer: Arguments length mismatch');

        for (uint256 i = 0; i < addresses.length; i++) {
            address account = addresses[i];
            uint256 alloc = allocations[i];

            // Skip already added users
            if (allocation[account] > 0) {
                emit DuplicateAllocationSkipped(account, alloc, allocation[account]);
                continue;
            }

            allocation[account] = alloc;
            totalTokens += alloc;
            accounts.push(account);

            for (uint256 j = 0; j < claimed[i].length; j++) {
                userClaimedPerClaim[account][j] = claimed[i][j];
                claimedTotal[account] += claimed[i][j];
                totalClaimedTokens += claimed[i][j];
            }
        }
    }

    function transferAllocation(address from, address to) external override onlyOwner {
        require(allocation[from] > 0, 'User has no allocation');
        require(allocation[to] == 0, "Can't transfer to an address with existing allocation");
        require(transferredAccountsMap[from] == address(0), 'User has already been transferred');
        require(transferredAccountsMap[to] == address(0), "Can't transfer to an address that has been transferred");
        require(isAccountEligible(from), 'Account is ineligible due to the Diamond Hands rule');

        accounts.push(to);

        transferredAccountsMap[from] = to;
        transferredAccounts.push([from, to]);

        allocation[to] = allocation[from];
        allocation[from] = 0;

        claimedTotal[to] = claimedTotal[from];
        claimedTotal[from] = 0;

        for (uint256 i = 0; i < claims.length; i++) {
            userClaimedPerClaim[to][i] = userClaimedPerClaim[from][i];
            userClaimedPerClaim[from][i] = 0;
        }

        emit AllocationTransferred(from, to);
    }
}