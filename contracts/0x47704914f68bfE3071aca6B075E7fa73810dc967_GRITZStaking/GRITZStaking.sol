/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

//********************************************************************************
//********************************************************************************
//********************************************************************************
//*******             **.            ***     ***             **             ******
//******         *******              *       *                              *****
//******       **     **       ****   *       *              **              *****
//******         **    *              *       ******    ,***********,    *********
//******               *       **   ***       ******    *******              *****
//********************************************************************************
//********************************************************************************
//********************************************************************************
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function burn(uint256 _value) external returns (bool success);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GRITZStaking is Ownable {
    IERC20 private gritzToken;
    uint256 private initialLockedTokens;
    bool private isInitialized;

    uint256 public totalStaked;
    uint256 public totalRewards;
    bool public lockedTokensInitialized;
    bool public stakingOpen;

    struct Staker {
        uint256 stakedAmount;
        uint256 lastClaimedBlock;
        uint256 totalRewards;
        uint256 stakeStartTime;
        uint256 stakeDuration;
        bool autoCompound;
    }

    mapping(address => Staker) public stakers;

    event Staked(address indexed staker, uint256 amount, uint256 duration, bool autoCompound);
    event Unstaked(address indexed staker, uint256 amount);
    event Claimed(address indexed staker, uint256 amount);
    event AutoCompounded(address indexed staker, uint256 amount);
    event Compounded(address indexed staker, uint256 oldRewards, uint256 newRewards);
    event StakingOpened();
    event StakingClosed();
    event LockedTokensInitialized(); // New event declaration

    constructor(IERC20 _gritzToken) {
        gritzToken = _gritzToken;
        stakingOpen = false; // Staking is initially closed
    }

    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }

    function initializeLockedTokens() external onlyOwner {
    require(!isInitialized, "Already initialized");
    initialLockedTokens = gritzToken.balanceOf(address(this));
    isInitialized = true;
    lockedTokensInitialized = true; // Set lockedTokensInitialized to true
    emit LockedTokensInitialized();
    }


    function isLockedTokensInitialized() public view returns (bool) {
    return lockedTokensInitialized;
}

    function getGritzBalance(address _user) public view returns (uint256) {
        return gritzToken.balanceOf(_user);
    }

	function getUnclaimedRewards(address _user) public view returns (uint256 unclaimedRewards) {
		unclaimedRewards = getRewards(_user);
	}
	
	modifier onlyWhenStakingOpen() {
    require(stakingOpen, "Staking is closed");
    _;
}

function openStaking() external onlyOwner {
    require(!stakingOpen, "Staking is already open");
    stakingOpen = true;
    emit StakingOpened();
}

function closeStaking() external onlyOwner {
    require(stakingOpen, "Staking is already closed");
    stakingOpen = false;
    emit StakingClosed();
}

function burnTokens(uint256 _amount) external onlyOwner {
    require(_amount > 0, "Invalid burn amount");
    require(gritzToken.balanceOf(address(this)) >= _amount, "Insufficient tokens in the contract");

    // Burn the specified amount of tokens
    require(gritzToken.burn(_amount), "Token burn failed");
}

function stake(uint256 _amount, uint256 _durationInDays, bool _autoCompound) external onlyWhenStakingOpen {
    require(_amount > 0, "Invalid stake amount");
    require(_durationInDays == 7 || _durationInDays == 30 || _durationInDays == 90 || _durationInDays == 182 || _durationInDays == 365, "Invalid staking duration");

    // Convert duration from days to seconds
    uint256 _duration = _durationInDays * 1 days;

    // Adjust the stake amount based on token decimals
    uint256 decimalFactor = 10 ** 18; // Assuming 18 decimal places
    uint256 adjustedAmount = _amount * decimalFactor;

    // Check if the staker has approved the staking contract to spend their tokens
    if (gritzToken.allowance(msg.sender, address(this)) < adjustedAmount) {
        // If the staker has not approved the staking contract, prompt them to do so
        require(gritzToken.approve(address(this), adjustedAmount), "Approval failed");
    }

    Staker storage staker = stakers[msg.sender];

    if (staker.stakedAmount > 0) {
        uint256 rewards = getRewards(msg.sender);
        if (rewards > 0) {
            staker.totalRewards += rewards;
            totalRewards += rewards;
            require(gritzToken.transfer(msg.sender, rewards), "Transfer failed");
            emit Claimed(msg.sender, rewards);
        }
    }

    staker.stakedAmount += adjustedAmount;
    staker.lastClaimedBlock = block.number;
    staker.stakeStartTime = block.timestamp;
    staker.stakeDuration = _duration;
    staker.autoCompound = _autoCompound;

    totalStaked += adjustedAmount;
    require(gritzToken.transferFrom(msg.sender, address(this), adjustedAmount), "Transfer failed");

    emit Staked(msg.sender, _amount, _durationInDays, _autoCompound);
}

function unstake() external onlyWhenStakingOpen {
    Staker storage staker = stakers[msg.sender];
    require(staker.stakedAmount > 0, "No tokens staked");
    require(block.timestamp >= staker.stakeStartTime + staker.stakeDuration, "Stake duration not elapsed");

    uint256 rewards = getRewards(msg.sender);
    if (rewards > 0) {
        staker.totalRewards += rewards;
        totalRewards += rewards;
        gritzToken.transfer(msg.sender, rewards);
        emit Claimed(msg.sender, rewards);
    }

    uint256 amount = staker.stakedAmount;
    staker.stakedAmount = 0;
    staker.lastClaimedBlock = 0;
    staker.totalRewards = 0;
    staker.stakeStartTime = 0;
    staker.stakeDuration = 0;
    staker.autoCompound = false;

    totalStaked -= amount;
    gritzToken.transfer(msg.sender, amount);

    emit Unstaked(msg.sender, amount);
    }
    
    function getLockedTokens() external view returns (uint256) {
    return initialLockedTokens;
}

function getStakeDuration(address _user) external view returns (uint256) {
    return stakers[_user].stakeDuration;
}

function getRewards(address _staker) public view returns (uint256) {
    Staker memory staker = stakers[_staker];
    uint256 blocksElapsed = block.number - staker.lastClaimedBlock;
    uint256 stakingAPY = _getStakingAPY(staker.stakeDuration);
    uint256 rewards = (staker.stakedAmount * stakingAPY * blocksElapsed) / (100 * 2102400);
    return rewards;
}

function claimRewards() external onlyWhenStakingOpen {
    Staker storage staker = stakers[msg.sender];
    require(block.timestamp >= staker.stakeStartTime + staker.stakeDuration, "Stake duration not elapsed");
    uint256 rewards = getRewards(msg.sender);
    require(rewards > 0, "No rewards to claim");

    if (staker.autoCompound) {
        uint256 oldRewards = staker.totalRewards;
        staker.totalRewards += rewards;
        staker.lastClaimedBlock = block.number;
        totalRewards += rewards;

        emit AutoCompounded(msg.sender, rewards);
        emit Compounded(msg.sender, oldRewards, staker.totalRewards);
    } else {
        staker.lastClaimedBlock = block.number;
        staker.totalRewards += rewards;
        totalRewards += rewards;
        require(gritzToken.transfer(msg.sender, rewards), "Transfer failed");

        emit Claimed(msg.sender, rewards);
    }
}

function compoundRewards() external onlyWhenStakingOpen {
    Staker storage staker = stakers[msg.sender];
    require(staker.autoCompound, "Auto-compound not enabled");
    uint256 rewards = getRewards(msg.sender);
    require(rewards > 0, "No rewards to compound");

    uint256 oldRewards = staker.totalRewards;
    staker.totalRewards += rewards;
    staker.lastClaimedBlock = block.number;
    totalRewards += rewards;

    emit Compounded(msg.sender, oldRewards, staker.totalRewards);
    emit AutoCompounded(msg.sender, rewards);
}

function enableAutoCompound() external onlyWhenStakingOpen {
    Staker storage staker = stakers[msg.sender];
    require(staker.stakedAmount > 0, "No tokens staked");
    require(!staker.autoCompound, "Auto-compound already enabled");

    staker.autoCompound = true;

    emit Staked(msg.sender, staker.stakedAmount, staker.stakeDuration, true);
}

function disableAutoCompound() external onlyWhenStakingOpen {
    Staker storage staker = stakers[msg.sender];
    require(staker.autoCompound, "Auto-compound not enabled");

    staker.autoCompound = false;

    emit Staked(msg.sender, staker.stakedAmount, staker.stakeDuration, false);
}

function isStakingOpen() public view returns (bool) {
    return stakingOpen;
 }

function getCurrentAPYFor365Days() public view returns (uint256) {
    return _getStakingAPY(365 days) / 100; // Divide by 100 to convert to percentage
}

function getCurrentAPYFor182Days() public view returns (uint256) {
    return _getStakingAPY(182 days) / 100; // Divide by 100 to convert to percentage
}

function getCurrentAPYFor90Days() public view returns (uint256) {
    return _getStakingAPY(90 days) / 100; // Divide by 100 to convert to percentage
}

function getCurrentAPYFor30Days() public view returns (uint256) {
    return _getStakingAPY(30 days) / 100; // Divide by 100 to convert to percentage
}

function getCurrentAPYFor7Days() public view returns (uint256) {
    return _getStakingAPY(7 days) / 100; // Divide by 100 to convert to percentage
}


function _getStakingAPY(uint256 _stakingDuration) internal view returns (uint256) {
    // Calculate reduction factor based on the total staked amount
    uint256 reductionFactor = _calculateReductionFactor();

    if (_stakingDuration >= 365 days) {
        uint256 baseAPY = 36500; // 365.00% APY
        uint256 reducedAPY = baseAPY - (baseAPY * reductionFactor / 100);
        return reducedAPY > 0 ? reducedAPY : 0;
    } else if (_stakingDuration >= 182 days) {
        uint256 baseAPY = 12500; // 125.00% APY
        uint256 reducedAPY = baseAPY - (baseAPY * reductionFactor / 100);
        return reducedAPY > 0 ? reducedAPY : 0;
    } else if (_stakingDuration >= 90 days) {
        uint256 baseAPY = 5000; // 50.00% APY
        uint256 reducedAPY = baseAPY - (baseAPY * reductionFactor / 100);
        return reducedAPY > 0 ? reducedAPY : 0;
    } else if (_stakingDuration >= 30 days) {
        uint256 baseAPY = 1000; // 10.00% APY
        uint256 reducedAPY = baseAPY - (baseAPY * reductionFactor / 100);
        return reducedAPY > 0 ? reducedAPY : 0;
    } else if (_stakingDuration >= 7 days) {
        uint256 baseAPY = 250; // 2.5% APY
        uint256 reducedAPY = baseAPY - (baseAPY * reductionFactor / 100);
        return reducedAPY > 0 ? reducedAPY : 0;
    } else {
        return 0; // Not eligible for rewards
    }
}

function _calculateReductionFactor() internal view returns (uint256) {
    // The base staking amount at which the APY starts to decrease
    uint256 baseStakingAmount = 1e18; // 1 token

    if (totalStaked <= baseStakingAmount) {
        return 0;
    }

    // Logarithm base 2 of the total staked amount divided by the base staking amount
    // This gives us the number of times the total staked amount has doubled
    uint256 doublingTimes = _log2(totalStaked / baseStakingAmount);

    return doublingTimes;
}

// Calculate the binary logarithm of a number
function _log2(uint256 x) internal pure returns (uint256) {
    uint256 y = 0;
    uint256 val = x;
    while (val > 1) {
        val >>= 1;
        y += 1;
    }
    return y;
}
}