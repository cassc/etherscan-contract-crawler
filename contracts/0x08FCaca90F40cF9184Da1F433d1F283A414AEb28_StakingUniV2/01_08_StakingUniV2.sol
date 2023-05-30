// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract StakingUniV2 is ReentrancyGuard, Ownable, Pausable {
    IERC20 public stakingToken; // UNI-V2 LP token
    IERC20 public rewardToken; // HANePlatform token

    constructor(address _stakingToken, address _rewardToken) onlyOwner {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    uint256 public constant hanTokenPerLpToken = 3860855150859520; // Quantity of HAN tokens rewarded per LP token

    uint256 public totalSupply; // Total amount of token staked
    uint256 public tokenQuota = 10000 ether; // The total amount of LP token that users can stake to contract

    struct Staker {
        uint256 amount;
        uint256 startTime;
        uint256 rewardReleased;
        uint256 unclaimedReward;
    }

    mapping(address => Staker) public stakers;

    // ------------------ Staking Functions ------------------ //

    function stake(uint256 _amount) public nonReentrant whenNotPaused {
        Staker storage staker = stakers[msg.sender];
        require(_amount > 0, "Cannot stake 0");
        require(_amount + totalSupply <= tokenQuota, "Too Many Token");
        require(rewardToken.balanceOf(address(this))  > _amount * hanTokenPerLpToken * 365 days / 10**18, "Total amount of rewards is too high");
        totalSupply += _amount;
        if (staker.amount > 0) {
            _unclaimeReward();
            _staker(_amount);
        } else {
            _staker(_amount);
        }
    }

    function _staker(uint256 _amount) internal {
        Staker storage staker = stakers[msg.sender];
        staker.amount += _amount;
        staker.startTime = block.timestamp;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }


    // "WITHDRAW" function
    function withdraw(uint256 _amount) public nonReentrant {
        Staker storage staker = stakers[msg.sender];
        require(_amount > 0, "Cannot withdraw 0");
        totalSupply -= _amount;
        _unclaimeReward();
        staker.amount -= _amount;
        staker.startTime = block.timestamp;
        stakingToken.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    // "CLAIM" function
    function claimReward() public nonReentrant {
        Staker storage staker = stakers[msg.sender];
        _unclaimeReward();
        rewardToken.transfer(msg.sender, staker.unclaimedReward);
        staker.rewardReleased += staker.unclaimedReward;
        emit RewardPaid(msg.sender, staker.unclaimedReward);
        staker.unclaimedReward = 0;
        staker.startTime = block.timestamp;
    }
    
    function _unclaimeReward() internal {
        Staker storage staker = stakers[msg.sender];
        uint256 stakedTime = block.timestamp - staker.startTime;
        staker.unclaimedReward += stakedTime * staker.amount * hanTokenPerLpToken / 10**18;
    }

    function rewardView(address _user) public view returns (uint256) {
        uint256 stakedTime = block.timestamp - stakers[msg.sender].startTime;
        return stakers[_user].amount * hanTokenPerLpToken * stakedTime / 10**18;
    }

    function setTokenVolume(uint256 _newQuota) public onlyOwner {
        require(_newQuota > totalSupply, "Too Small Volume");
        tokenQuota = _newQuota;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        emit RecoveredERC20(_tokenAddress, _tokenAmount);
    }

function recoverERC721(address _tokenAddress, uint256 _tokenId) external onlyOwner {
        IERC721(_tokenAddress).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit RecoveredERC721(_tokenAddress, _tokenId);
    }

    // ------------------ EVENTS ------------------ //

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RecoveredERC20(address token, uint256 amount);
    event RecoveredERC721(address token, uint256 tokenId);
}