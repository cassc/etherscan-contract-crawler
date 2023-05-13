// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//   ____  _                           _
//  / ___|| | ___  ___ _ __  _   _    | | ___   ___   __ _ _ __  _ __
//  \___ \| |/ _ \/ _ \ '_ \| | | |_  | |/ _ \ / _ \ / _` | '_ \| '_ \
//   ___) | |  __/  __/ |_) | |_| | |_| | (_) |  __/| (_| | |_) | |_) |
//  |____/|_|\___|\___| .__/ \__, |\___/ \___/ \___(_)__,_| .__/| .__/
//                    |_|    |___/                        |_|   |_|
// Visit https://sleepyjoe.app
// Join our telegram https://t.me/+n3tejharUCRjNTY0
// Join our discord https://discord.gg/XKdUt3bnV4

interface ISleepyToken {
    function payStimulus(address recipient, uint256 stimulusAmount) external;

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

abstract contract ReentrancyGuard {
    bool internal locked;

    modifier nonReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract BankOfSleepyJoe is ReentrancyGuard {
    ISleepyToken public sleepy;
    address public owner;
    uint256 interestRateBPS;
    mapping(address => uint256) public amountDeposited;
    mapping(address => uint256) public lastInteracted;
    uint256 public totalDeposited;
    uint256 public cooldownPeriod = 1 days;

    constructor(address _sleepy) {
        owner = msg.sender;
        sleepy = ISleepyToken(_sleepy);
        interestRateBPS = 690;
    }

    /// @notice Allows users to reinvest their stimulus rewards, triggers a cooldown period
    function reinvest() external nonReentrant {
        require(amountDeposited[msg.sender] > 0, "No active deposits");
        require(
            block.timestamp - lastInteracted[msg.sender] > cooldownPeriod,
            "Cooldown period has not passed"
        );
        uint256 stimulusReward = getStimulusReward(msg.sender);
        lastInteracted[msg.sender] = block.timestamp;
        sleepy.payStimulus(address(this), stimulusReward);
        amountDeposited[msg.sender] += stimulusReward;
        totalDeposited += stimulusReward;
    }

    /// @notice Allows users to claim their stimulus rewards, triggers a cooldown period
    function claimStimulus() external nonReentrant {
        require(amountDeposited[msg.sender] > 0, "No active deposits");
        require(
            block.timestamp - lastInteracted[msg.sender] > cooldownPeriod,
            "Cooldown period has not passed"
        );
        uint256 stimulusReward = getStimulusReward(msg.sender);
        lastInteracted[msg.sender] = block.timestamp;
        sleepy.payStimulus(msg.sender, stimulusReward);
    }

    /// @notice Allows users to deposit funds into the bank
    /// @notice Accrued interest is compounded if the cooldown period has passed
    /// @param _amount The amount of tokens to deposit
    function deposit(uint _amount) external nonReentrant {
        require(_amount > 0, "amount cannot be 0");
        uint256 stimulusReward = getStimulusReward(msg.sender);
        lastInteracted[msg.sender] = block.timestamp;
        sleepy.transferFrom(msg.sender, address(this), _amount);
        if (stimulusReward > 0) {
            sleepy.payStimulus(address(this), stimulusReward);
            amountDeposited[msg.sender] += stimulusReward;
        }
        amountDeposited[msg.sender] += _amount;
        totalDeposited += _amount + stimulusReward;
    }

    /// @notice Allows users to withdraw all their funds
    /// @notice Accrued interest is only paid out if the cooldown period has passed
    function withdrawAll() external nonReentrant {
        uint256 depositedAmount = amountDeposited[msg.sender];
        uint256 stimulusReward = getStimulusReward(msg.sender);
        amountDeposited[msg.sender] = 0;
        if (block.timestamp - lastInteracted[msg.sender] > cooldownPeriod) {
            sleepy.payStimulus(msg.sender, stimulusReward);
        }
        lastInteracted[msg.sender] = block.timestamp;
        sleepy.transfer(msg.sender, depositedAmount);
        totalDeposited -= depositedAmount;
    }

    /// @dev Calculates the amount of stimulus rewards a user has accrued
    /// @dev If the cooldown period has not passed, the user will not receive any rewards
    /// @return The amount of stimulus rewards a user has accrued
    function getStimulusReward(
        address userAddress
    ) public view returns (uint256) {
        uint256 oneYear = 31536000;
        uint256 stimulusRewardPerYear = (amountDeposited[userAddress] *
            interestRateBPS) / 10000;
        uint256 timeElapsed = block.timestamp - lastInteracted[userAddress];
        uint256 stimulusReward = (stimulusRewardPerYear * timeElapsed) /
            oneYear;
        return stimulusReward;
    }

    /// @notice Admin funtion to change the interest rate
    function setInterestRate(uint256 _interestRateBPS) public {
        if (msg.sender != owner) {
            return;
        }
        interestRateBPS = _interestRateBPS;
    }

    /// @notice Check if user is in cooldown period
    function isUserInCooldown() external view returns (bool) {
        return block.timestamp - lastInteracted[msg.sender] < cooldownPeriod;
    }

    /// @notice Admin funtion to change the cooldown period
    function setCooldownPeriod(uint256 _cooldownDuration) external {
        if (msg.sender != owner) {
            return;
        }
        cooldownPeriod = _cooldownDuration;
    }

    /// @notice Admin funtion to change the owner
    function transferOwner(address newOwner) public {
        if (msg.sender != owner) {
            return;
        }
        owner = newOwner;
    }

    /// @notice View function to get user data
    function getUserData(address user) external view returns (uint, uint) {
        return (amountDeposited[user], lastInteracted[user]);
    }
}