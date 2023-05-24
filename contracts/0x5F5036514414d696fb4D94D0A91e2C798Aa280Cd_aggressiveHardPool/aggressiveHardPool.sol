/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

// This is a heavily modified version of the Synthetix staking contract.

contract aggressiveHardPool {
    address public tokenAddress; // ERC20 being staked.
    uint256 public rewardChance; // Reward chance.
    address public splitAddress = 0x6de77170E1F71B80642D55c29f595aC37b91eBf6; // Splitter, set to burn as default.
    uint256 public rewardPercentage; // Reward generated per hour (as a percentage of staker.amount).
    uint256 public riskModifier; // Additional risk generated per hour (as a flat percentage).
    address public owner; // Contract owner (initialized in constructor as deployer).
    address[] public stakerAddresses; // Leaderboard right insdie the contract, lol.
    uint256 public addressCount; // Counts addresses for leaderboard concatenation.

    struct Staker {
        uint256 amount;
        uint256 time;
        uint256 wins;
        uint256 losses;
    }

    mapping(address => Staker) public stakers;

    constructor(address _tokenAddress, uint256 _rewardChance) {
        tokenAddress = _tokenAddress;
        rewardChance = _rewardChance;
        riskModifier = 5;
        rewardPercentage = 5;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function stakeTokens(uint256 _amount) public { // Users stake an amount of tokens.
        Staker storage staker = stakers[msg.sender];
        require(_amount > 0, "Amount cannot be zero");
        require(staker.time == 0, "Complete your current staking cycle first.");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        
        staker.amount += _amount;
        if (staker.time == 0) {
            staker.time = block.timestamp; // Set the start time if it's not already set
        }
    }


    function claimReward() public { // Users claim their rewards to see if they've won or lost.
        Staker memory staker = stakers[msg.sender];
        require(staker.amount > 0, "No tokens staked");
        require(block.timestamp >= staker.time + 0.5 hours, "You need to stake your tokens for a minimum of 30 minutes, try again soon.");

        uint256 elapsedTime = (block.timestamp - staker.time) / 3600; // Calculate elapsed time in hours
        uint256 reward = staker.amount + (staker.amount * elapsedTime * 45) / 1000;


        uint256 additionalModifier = (staker.amount * elapsedTime * 43) / 1000;
        additionalModifier = additionalModifier % 101; // Ensure the value is between 0 and 100
        rewardChance += additionalModifier;

        if (rewardChance > 0 && block.timestamp % 100 < rewardChance) {

            // Transfer 10% of staker's balance to burn address and clear balance
            uint256 splitAmount = staker.amount / 5;
            if (splitAmount > 0) {
                IERC20(tokenAddress).transfer(splitAddress, splitAmount);
            }

            // Clear stakers balance
            stakers[msg.sender].amount = 0;
            stakers[msg.sender].time = 0;
            stakers[msg.sender].losses += 1;
            emit Loss(msg.sender, reward);
        } else {

            // Transfer 10% of reward balance to burn address and the rest to the staker
            uint256 splitAmount = reward / 10;
            uint256 stakerAmount = reward - splitAmount;
            if (splitAmount > 0) {
                IERC20(tokenAddress).transfer(splitAddress, splitAmount);
            }
            if (stakerAmount > 0) {
                IERC20(tokenAddress).transfer(msg.sender, stakerAmount);
            }

            // Clear stakers balance
            if (staker.amount > 0) {
                stakers[msg.sender].amount = 0;
            }
            if (staker.time > 0) {
                stakers[msg.sender].time = 0;
            }
            stakers[msg.sender].wins += 1;
            emit Win(msg.sender, reward);
        }
    }

    event Loss(address indexed staker, uint256 reward);
    event Win(address indexed staker, uint256 reward);

    function setSplitAddress(address _splitAddress) external onlyOwner { // Update the split address.
        splitAddress = _splitAddress;
    }

    function setRewardChance(uint256 _newRewardChance) external onlyOwner { // Update the reward chance.
        rewardChance = _newRewardChance;
    }

    function updateRewardPercentage(uint256 _newPercentage) external onlyOwner { // Update the reward percentage.
        rewardPercentage = _newPercentage;
    }

    function updateRiskModifier(uint256 _newRiskModifier) external onlyOwner { // Update risk modifier.
        riskModifier = _newRiskModifier;
    }

    function withdrawTokens() public onlyOwner { // Owner can remove the tokenAddress ERC20 if needed.
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "Contract has no balance");
        IERC20(tokenAddress).transfer(owner, balance);
    }

    function getCurrentRewardAmount(address _staker) public view returns (uint256) { // Read reward of staker.
        Staker memory staker = stakers[_staker];
        require(staker.amount > 0, "No tokens staked");

        uint256 elapsedTime = (block.timestamp - staker.time) / 3600; // Calculate elapsed time in hours
        uint256 reward = staker.amount + (staker.amount * elapsedTime * 45) / 1000;
        return reward;
    }


    function getCurrentRewardChance(address _staker) public view returns (uint256) { // Read risk of staker.
        Staker memory staker = stakers[_staker];
        require(staker.amount > 0, "No tokens staked");

        uint256 elapsedTime = (block.timestamp - staker.time) / 3600; // Calculate elapsed time in hours
        uint256 additionalModifier = (staker.amount * elapsedTime * 43) / 1000;
        additionalModifier = additionalModifier % 101; // Ensure the value is between 0 and 100
        uint256 currentChance = rewardChance + additionalModifier;
        return currentChance;
    }

    function getStakerWins(address _staker) public view returns (uint256 wins) { // Read wins of staker.
        Staker memory staker = stakers[_staker];
        wins = staker.wins;
    }

    function getStakerLosses(address _staker) public view returns (uint256 losses) { // Read losses of staker.
        Staker memory staker = stakers[_staker];
        losses = staker.losses;
    }

    function clearStaker(address _staker) public view onlyOwner { // Read losses of staker.
        Staker memory staker = stakers[_staker];
        staker.amount = 0;
        staker.time = 0;
    }

    function getTopStakers() public view returns (address[] memory, uint256[] memory) {
        uint256 count = 10;
        uint256 length = count;
        if (length > addressCount) {
            length = addressCount;
        }

        address[] memory topStakers = new address[](length);
        uint256[] memory winCounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 maxWins = 0;
            address maxStaker;

            for (uint256 j = 0; j < addressCount; j++) {
                address currentStaker = stakerAddresses[j];
                uint256 currentWins = stakers[currentStaker].wins;

                if (currentWins > maxWins) {
                    bool exists = false;
                    for (uint256 k = 0; k < i; k++) {
                        if (topStakers[k] == currentStaker) {
                            exists = true;
                            break;
                        }
                    }

                    if (!exists) {
                        maxWins = currentWins;
                        maxStaker = currentStaker;
                    }
                }
            }

            topStakers[i] = maxStaker;
            winCounts[i] = maxWins;
        }

        return (topStakers, winCounts);
    }
}