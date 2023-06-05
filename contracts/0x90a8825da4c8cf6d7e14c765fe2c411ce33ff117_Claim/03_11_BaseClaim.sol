// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseClaim is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct UserInfo {
        uint256 reward;
        uint256 withdrawn;
    }
    mapping(address => UserInfo) public userInfo;

    uint256 public claimTime; // Time at which claiming can start

    ERC20 public immutable rewardToken; // Token that is distributed

    event RewardClaimed(
        address indexed user,
        uint256 indexed withdrawAmount,
        uint256 totalWithdrawn
    );

    uint256 public totalRewards;
    uint256 public totalWithdrawn;

    constructor(ERC20 _rewardToken) {
        rewardToken = ERC20(_rewardToken);

        claimTime = block.timestamp;
    }

    ////
    // Modifiers
    ////
    modifier onlyWithRewards(address addr) {
        require(userInfo[addr].reward > 0, "Address has no rewards");
        _;
    }

    ////
    // Functions
    ////
    function addUserReward(address _user, uint256 _amount) internal {
        UserInfo storage user = userInfo[_user];
        uint256 newReward = user.reward.add(_amount);

        totalRewards = totalRewards.add(_amount);
        user.reward = newReward;
    }

    function setUserReward(address _user, uint256 _amount) internal {
        UserInfo storage user = userInfo[_user];

        totalRewards = totalRewards.add(_amount).sub(user.reward);
        user.reward = _amount;

        assert(user.reward >= user.withdrawn);
    }

    function freezeUserReward(address _user) internal {
        UserInfo storage user = userInfo[_user];

        uint256 change = user.reward.sub(user.withdrawn);

        user.reward = user.withdrawn;
        totalRewards = totalRewards.sub(change);
    }

    function claim() external onlyWithRewards(msg.sender) {
        UserInfo storage user = userInfo[msg.sender];

        uint256 withdrawAmount = getWithdrawableAmount(msg.sender);

        rewardToken.safeTransfer(msg.sender, withdrawAmount);

        user.withdrawn = user.withdrawn.add(withdrawAmount);
        totalWithdrawn = totalWithdrawn.add(withdrawAmount);

        assert(user.withdrawn <= user.reward);

        emit RewardClaimed(msg.sender, withdrawAmount, user.withdrawn);
    }

    function getWithdrawableAmount(address _user)
        public
        view
        returns (uint256)
    {
        UserInfo memory user = userInfo[_user];

        uint256 unlockedAmount = calculateUnlockedAmount(
            user.reward,
            block.timestamp
        );

        return unlockedAmount.sub(user.withdrawn);
    }

    // This is a timed vesting contract
    //
    // Claimants can claim 100% of ther claim upon claimTime.
    //
    // Can be overriden in contracts that inherit from this one.
    function calculateUnlockedAmount(uint256 _totalAmount, uint256 _timestamp)
        internal
        view
        virtual
        returns (uint256)
    {
        return _timestamp > claimTime ? _totalAmount : 0;
    }

    function totalAvailableAfter()
        public
        view
        virtual
        returns (uint256)
    {
        return claimTime;
    }

    function withdrawRewardAmount(uint256 amount) external onlyOwner {
        rewardToken.safeTransfer(
            msg.sender,
            amount
        );
    }

    function emergencyWithdrawToken(ERC20 tokenAddress) external onlyOwner {
        tokenAddress.safeTransfer(
            msg.sender,
            tokenAddress.balanceOf(address(this))
        );
    }
}