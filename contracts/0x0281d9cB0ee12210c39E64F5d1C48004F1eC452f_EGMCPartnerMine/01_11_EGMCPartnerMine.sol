// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IEGMCMine.sol";

contract EGMCPartnerMine is ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    // STATE VARIABLES

    IERC20 public rewardsToken;
    IEGMCMine public mine;
    uint public maxParticipants;
    uint public capPerParticipant;
    uint public periodFinish = 0;
    uint public rewardRate = 0;
    uint public rewardsDuration = 2 weeks;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint private _totalSupply;
    uint private _totalParticipants;
    mapping(address => uint) private _balances;

    // CONSTRUCTOR

    constructor(
        address _rewardsToken,
        address _mine
    ) {
        rewardsToken = IERC20(_rewardsToken);
        mine = IEGMCMine(_mine);
    }

    // VIEWS

    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    function totalParticipants() external view returns (uint) {
        return _totalParticipants;
    }

    function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate.mul(rewardsDuration);
    }

    function min(uint a, uint b) public pure returns (uint) {
        return a < b ? a : b;
    }

    // PUBLIC FUNCTIONS

    function join(uint amount)
        external
        nonReentrant
        whenNotPaused
        updateReward(_msgSender())
    {
        require(amount > 0, "Cannot stake 0");
        require(
            amount <= mine.getMiningPower(_msgSender()),
            "You do not have enough mining power"
        );
        require(
            _balances[_msgSender()].div(1e18).add(amount) <= capPerParticipant, 
            "This amount would bring you above the cap per participant"
        );

        amount = amount.mul(1e18);

        _totalSupply = _totalSupply.add(amount);
        if (_balances[_msgSender()] == 0) {
            require(
                _totalParticipants.add(1) <= maxParticipants,
                "This action would bring the mine above the max participant count"
            );
            _totalParticipants = _totalParticipants.add(1);
        }
        _balances[_msgSender()] = _balances[_msgSender()].add(amount);
        
        emit Joined(_msgSender(), amount);
    }

    function claim() 
        public 
        nonReentrant 
        whenNotPaused
        updateReward(_msgSender()) 
    {
        uint reward = rewards[_msgSender()];
        if (reward > 0) {
            rewards[_msgSender()] = 0;
            rewardsToken.safeTransfer(_msgSender(), reward);
            emit RewardPaid(_msgSender(), reward);
        }
    }

    // RESTRICTED FUNCTIONS

    function notifyRewardAmount(uint reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        uint balanceBefore = rewardsToken.balanceOf(address(this));
        rewardsToken.safeTransferFrom(_msgSender(), address(this), reward);
        uint balance = rewardsToken.balanceOf(address(this));
        uint deltaBalance = balance.sub(balanceBefore);
        if (deltaBalance < reward) reward = deltaBalance;

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint remaining = periodFinish.sub(block.timestamp);
            uint leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function recoverERC20(address tokenAddress, uint tokenAmount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function setMaxParticipants(uint _maxParticipants) external onlyOwner {
        maxParticipants = _maxParticipants;
    }

    function setCapPerParticipant(uint _capPerParticipant) external onlyOwner {
        capPerParticipant = _capPerParticipant;
    }

    function enableDepositing() external onlyOwner {
        require(paused(), "Contract is not paused");
        _unpause();
    }

    function disableDepositing() external onlyOwner {
        require(!paused(), "Contract is already paused");
        _pause();
    }

    // *** MODIFIERS ***

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }

        _;
    }

    // EVENTS

    event RewardAdded(uint reward);
    event Joined(address indexed user, uint amount);
    event RewardPaid(address indexed user, uint reward);
    event RewardsDurationUpdated(uint newDuration);
    event Recovered(address token, uint amount);
}