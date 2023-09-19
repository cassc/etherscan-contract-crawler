// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract StakingV7_2 is ReentrancyGuard {
    using SafeMath for uint256;

    address public owner;
    address public stakevault;
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;
    uint256 public stakingTokenDecimals;
    uint256 public rewardTokenDecimals;
    string public stakingTokenName;
    string public rewardTokenName;
    string public contractType;

    uint256 public duration;
    uint256 public finishAt;
    uint256 public updatedAt;

    //claim rules
    uint256 public phase1;
    uint256 public phase2;
    uint256 public phase3;
    uint256 public phase4;

    uint256 public percentage1;
    uint256 public percentage2;
    uint256 public percentage3;
    
    // Reward to be paid out per second
    uint256 public rewardRate;
    // Sum of (reward rate * dt * rewardTokenDecimals / total supply)
    uint256 public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed since "updateReward"
    mapping(address => uint256) public rewards;

    // User Info
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public claimedRewards;
    mapping(address => uint256) public userStakeUpdateTime;
    mapping(address => uint256) public lastClaimedTime;
    mapping(address => uint256) public userLastTimeStaked;


    // Total staked amount
    uint256 public totalSupply;
    // Total claimed amount
    uint256 public totalClaimed;
    // Total users
    uint256 public totalUsers;



    constructor(address _stakevault, address _stakingToken, address _rewardToken, uint256 _stakingTokenDecimals, uint256 _rewardTokenDecimals, string memory _stakingTokenName, string memory _rewardTokenName, string memory _contractType) {
        require(
            keccak256(bytes(_contractType)) == keccak256(bytes("stake")) || 
            keccak256(bytes(_contractType)) == keccak256(bytes("farm")),
            "Only use stake or farm as contractType"
        );
        
        owner = msg.sender;
        stakevault = _stakevault;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
        stakingTokenDecimals = _stakingTokenDecimals;
        rewardTokenDecimals = _rewardTokenDecimals;
        stakingTokenName = _stakingTokenName;
        rewardTokenName = _rewardTokenName;
        contractType = _contractType;
    }

    // Modifier: Only allows the contract owner to execute the function
    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }
    function updateRewardInternal(address _account) internal {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
    }

    // Stakes the specified amount of tokens
    function stake(uint256 _amount) external nonReentrant {
        updateRewardInternal(msg.sender);

        userLastTimeStaked[msg.sender] = block.timestamp;

        require(_amount > 0, "amount = 0");
        if (balanceOf[msg.sender] == 0) {
            userStakeUpdateTime[msg.sender] = block.timestamp;
            totalUsers += 1;
        }
        //transfer from RewardVault
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        //update info
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_amount);
        totalSupply = totalSupply.add(_amount);

        updateRewardInternal(msg.sender);
    }

    // Withdraws the specified amount of tokens
    function withdraw(uint256 _amount) external nonReentrant {
        updateRewardInternal(msg.sender);

        require(_amount > 0, "amount = 0");
        require(balanceOf[msg.sender] >= _amount, "amount > balance");
        stakingToken.transfer(msg.sender, _amount);
        //update info
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        updateRewardInternal(msg.sender);
    

        if (balanceOf[msg.sender] == 0) {
            userStakeUpdateTime[msg.sender] = 0;
            totalUsers -= 1;
        }
    }

    // Claims the rewards for the sender
    function getReward() external nonReentrant {
        updateRewardInternal(msg.sender);

        require(rewards[msg.sender] > 0, "No rewards to claim.");
        
        uint256 reward = rewards[msg.sender];
        uint256 userStakeEndTime = userLastTimeStaked[msg.sender] + phase4;

        if (block.timestamp < userStakeEndTime) {
            if (block.timestamp >= userLastTimeStaked[msg.sender] + phase3) {
                reward = (reward * percentage3) / 100;
            } else if (block.timestamp >= userLastTimeStaked[msg.sender] + phase2) {
                reward = (reward * percentage2) / 100;
            } else if (block.timestamp >= userLastTimeStaked[msg.sender] + phase1) {
                reward = (reward * percentage1) / 100;
            } else {
                revert("You cannot claim yet");
            }
        }
        rewardsToken.transferFrom(stakevault, msg.sender, reward);

        //update info
        rewards[msg.sender] = 0;
        claimedRewards[msg.sender] += reward;
        totalClaimed += reward;

        lastClaimedTime[msg.sender] = block.timestamp;
    }

    // Calculates the reward per token
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored.add(
            rewardRate.mul(lastTimeRewardApplicable().sub(updatedAt)).mul(10**rewardTokenDecimals).div(totalSupply)
        );
    }

    // Calculates the total earnings of an account
    function earned(address _account) public view returns (uint256) {
        return balanceOf[_account].mul(rewardPerToken().sub(userRewardPerTokenPaid[_account])).div(10**rewardTokenDecimals).add(rewards[_account]);
    }

    // Sets the duration of rewards distribution
    function setRewardsDurationDays(uint256 _durationInDays) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _durationInDays * 1 days;
    }

    // Notifies the contract about the amount of rewards to be distributed
    function notifyRewardAmount(uint256 _amount) external onlyOwner {
        updateRewardInternal(address(0));

        // Reward duration not started or expired. Set the duration first.
        if (block.timestamp > finishAt) {
            rewardRate = _amount.div(duration);
        } else {
            uint256 remainingRewards = finishAt.sub(block.timestamp).mul(rewardRate);
            rewardRate = _amount.add(remainingRewards).div(duration);
        }

        require(rewardRate > 0, "reward rate = 0");
        require(rewardRate.mul(duration) <= rewardsToken.balanceOf(address(stakevault)), "reward amount > balance");

        finishAt = block.timestamp.add(duration);
        updatedAt = block.timestamp;

        updateRewardInternal(address(0));
    }
    
    // Returns the last applicable timestamp for the rewards
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp <= finishAt ? block.timestamp : finishAt;
    }

    function userInfo(address _account) public view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 userPercentageX1000 = balanceOf[_account].mul(100000).div(totalSupply);
        uint256 userRewardRate = rewardRate.mul(userPercentageX1000).div(100000);
        uint256 userTimeUpdate = block.timestamp.sub(lastClaimedTime[_account]);
        uint256 userCurrentEarned = earned(_account);
        uint256 userEarningsNext24Hours = userRewardRate.mul(1 days);

        if (lastClaimedTime[_account] == 0) {
            userTimeUpdate = block.timestamp.sub(userStakeUpdateTime[_account]);
        }

        return (
            userPercentageX1000, // User percentage multiplied by 1000
            userRewardRate, // User reward rate
            userTimeUpdate, // Time elapsed since the last claim or stake update
            userCurrentEarned, // User's currently earned amount
            userEarningsNext24Hours // Estimated earnings in the next 24 hours
        );
    }
    function getEthBalance(address _address) public view returns (uint256) {
        return _address.balance;
    }
    function setPhaseAndPercentage (uint256 _phase1sec, uint256 _phase2sec, uint256 _phase3sec, uint256 _phase4sec,
    uint256 _percentage1, uint256 _percentage2, uint256 _percentage3) external onlyOwner{
        phase1 = _phase1sec;
        phase2 = _phase2sec;
        phase3 = _phase3sec;
        phase4 = _phase4sec;

        percentage1 = _percentage1;
        percentage2 = _percentage2;
        percentage3 = _percentage3;
    }
    function checkPhase(address user) public view returns (uint256, uint256, uint256, uint256) {
        uint256 currentPhase = 0;  // Default phase
        uint256 phasetime = 0;  // Default phasetime
        uint256 percent = 0; // Default Reward amount to withdraw
        uint256 remainingtime = 0; // Default time left

        if (block.timestamp > (userLastTimeStaked[user] + phase4)) {
            currentPhase = 4;
            percent = 100;
            phasetime = 0;
        } else if (block.timestamp > (userLastTimeStaked[user] + phase3)) {
            currentPhase = 3;
            percent = percentage3;
            phasetime = phase4;
            remainingtime = (userLastTimeStaked[user] + phase4) - block.timestamp;

        } else if (block.timestamp > (userLastTimeStaked[user] + phase2)) {
            currentPhase = 2;
            percent = percentage2;
            phasetime = phase3;
            remainingtime = (userLastTimeStaked[user] + phase3) - block.timestamp;

        } else if (block.timestamp > (userLastTimeStaked[user] + phase1)) {
            currentPhase = 1;
            percent = percentage1;
            phasetime = phase2;
            remainingtime = (userLastTimeStaked[user] + phase2) - block.timestamp;

        } else {
            phasetime = phase1;
            remainingtime = (userLastTimeStaked[user] + phase1) - block.timestamp;
        }
        return (currentPhase, phasetime, percent, remainingtime);
    }
}

// Interface for ERC20 token contract
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}