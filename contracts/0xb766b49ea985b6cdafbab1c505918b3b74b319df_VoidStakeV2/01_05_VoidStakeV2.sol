// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**

    website: https://void.cash/
    twitter: https://twitter.com/voidcasherc
    telegram: https://t.me/voidcashportal
    medium: https://medium.com/@voidcash
    
    prepare to enter the
    ██╗   ██╗ ██████╗ ██╗██████╗ 
    ██║   ██║██╔═══██╗██║██╔══██╗
    ██║   ██║██║   ██║██║██║  ██║
    ╚██╗ ██╔╝██║   ██║██║██║  ██║
     ╚████╔╝ ╚██████╔╝██║██████╔╝
      ╚═══╝   ╚═════╝ ╚═╝╚═════╝ 

 */

import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "./IMintableERC20.sol";

contract VoidStakeV2 is Ownable {

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error ZeroStakeAmount();
    error ZeroWithdrawAmount();
    error InvalidWithdrawAmount();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event VoidStaked(address indexed account, uint256 amount);
    event VoidWithdraw(address indexed account, uint256 amount);
    event VoidClaimed(address indexed account, uint256 amount);
    event RewardRateChanged(uint256 rewardRate);

    /* -------------------------------------------------------------------------- */
    /*                                public states                               */
    /* -------------------------------------------------------------------------- */
    address public immutable stakingTokenAddress;
    address public immutable rewardTokenAddress;

    uint256 public immutable rewardStartTime;

    uint256 public rewardRate = 1e13; // 0.00001 ether per second (0.864 ether per day)

    mapping(address => uint256) public userStakedAmount;
    uint256 public totalStaked;

    /* -------------------------------------------------------------------------- */
    /*                               private states                               */
    /* -------------------------------------------------------------------------- */
    uint256 private lastUpdatedAt;
    uint256 private currentRewardPerTokenE18;
    mapping(address => uint256) private userLastRewardPerToken;
    mapping(address => uint256) private userClaimableRewardTokens;

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    constructor(address _s, address _r) {
        stakingTokenAddress = _s;
        rewardTokenAddress = _r;

        // V1 startBlock: 15561017, timestamp: 1663511195
        // V1 endBlock: 15665460, timestamp: 1664773943
        // difference: 1262748
        rewardStartTime = block.timestamp - 1262748;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  modifiers                                 */
    /* -------------------------------------------------------------------------- */
    modifier updateRewardVariables(address account) {

        // calculate current rewardPerToken
        uint256 _currentRewardPerToken = calculateRewardPerTokenE18();

        // update currentRewardPerToken
        currentRewardPerTokenE18 = _currentRewardPerToken;

        // update lastUpdatedAt
        lastUpdatedAt = block.timestamp;

        // update userClaimableRewardTokens for user
        userClaimableRewardTokens[account] = calculateClaimableRewardTokens(account, _currentRewardPerToken);

        // update userLastRewardPerToken for user
        userLastRewardPerToken[account] = _currentRewardPerToken;

        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function claimableRewardTokens(address account) public view returns (uint256) {
        uint256 _currentRewardPerToken = calculateRewardPerTokenE18();
        return calculateClaimableRewardTokens(account, _currentRewardPerToken);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  external                                  */
    /* -------------------------------------------------------------------------- */
    function stake(uint256 amount) external updateRewardVariables(msg.sender) {

        // check amount
        if (amount == 0) { revert ZeroStakeAmount(); }

        // transfer
        IERC20(stakingTokenAddress).transferFrom(msg.sender, address(this), amount);

        // update variables
        totalStaked += amount;
        userStakedAmount[msg.sender] += amount;

        // event
        emit VoidStaked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external updateRewardVariables(msg.sender) {

        // check amount
        if (amount == 0) { revert ZeroWithdrawAmount(); }
        if (amount > userStakedAmount[msg.sender]) { revert InvalidWithdrawAmount(); }

        // transfer
        IERC20(stakingTokenAddress).transfer(msg.sender, amount);

        // update variables
        totalStaked -= amount;
        userStakedAmount[msg.sender] -= amount;

        // event
        emit VoidWithdraw(msg.sender, amount);
    }

    function claim() external updateRewardVariables(msg.sender) {

        // get reward
        uint256 reward = userClaimableRewardTokens[msg.sender];

        // do nothing
        if (reward == 0) { return; }

        // send reward
        userClaimableRewardTokens[msg.sender] = 0;
        IMintableERC20(rewardTokenAddress).mint(msg.sender, reward);

        // event
        emit VoidClaimed(msg.sender, reward);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   private                                  */
    /* -------------------------------------------------------------------------- */
    function calculateRewardPerTokenE18() private view returns (uint256) {

        // none staked
        if (totalStaked == 0) { return currentRewardPerTokenE18; }

        // cumulative reward per token
        // scaled by 1e18, otherwise rewards may go into the fractions and be erased
        return currentRewardPerTokenE18 + (rewardRate * (block.timestamp - lastUpdatedAt) * 1e18) / totalStaked;
    }

    function calculateClaimableRewardTokens(address account, uint256 _currentRewardPerToken) private view returns (uint256) {
        // undo the scaling by 1e18 performed in `calculateRewardPerTokenE18`
        return userClaimableRewardTokens[account] + userStakedAmount[account] * (_currentRewardPerToken - userLastRewardPerToken[account]) / 1e18;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;

        emit RewardRateChanged(_rewardRate);
    }
}