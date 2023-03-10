// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// solhint-disable not-rely-on-time
contract BaseClaim is Ownable {
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
    event ClaimsPaused();
    event ClaimsUnpaused();

    uint256 public totalRewards;
    uint256 public totalWithdrawn;

    bool public areClaimsPaused;

    constructor(address _rewardToken) {
        require(
            address(_rewardToken) != address(0),
            "Reward token must be set"
        );

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

    function pauseClaims() external onlyOwner {
        areClaimsPaused = true;

        emit ClaimsPaused();
    }

    function unPauseClaims() external onlyOwner {
        areClaimsPaused = false;

        emit ClaimsUnpaused();
    }

    function addUserReward(address _user, uint256 _amount) internal {
        UserInfo storage user = userInfo[_user];
        uint256 newReward = user.reward + _amount;

        totalRewards = totalRewards + _amount;
        user.reward = newReward;
    }

    function setUserReward(address _user, uint256 _amount) internal {
        UserInfo storage user = userInfo[_user];

        totalRewards = (totalRewards + _amount) - (user.reward);
        user.reward = _amount;

        require(user.reward >= user.withdrawn, "Invalid reward amount");
    }

    function freezeUserReward(address _user) internal {
        UserInfo storage user = userInfo[_user];

        uint256 change = user.reward - user.withdrawn;

        user.reward = user.withdrawn;
        totalRewards = totalRewards - change;
    }

    function claim() external onlyWithRewards(msg.sender) {
        require(!areClaimsPaused, "Claims are paused");

        UserInfo storage user = userInfo[msg.sender];

        uint256 withdrawAmount = getWithdrawableAmount(msg.sender);

        user.withdrawn = user.withdrawn + withdrawAmount;
        totalWithdrawn = totalWithdrawn + withdrawAmount;

        assert(user.withdrawn <= user.reward);

        rewardToken.safeTransfer(msg.sender, withdrawAmount);

        emit RewardClaimed(msg.sender, withdrawAmount, user.withdrawn);
    }

    function getWithdrawableAmount(
        address _user
    ) public view returns (uint256) {
        UserInfo memory user = userInfo[_user];

        uint256 unlockedAmount = calculateUnlockedAmount(
            user.reward,
            block.timestamp
        );

        return unlockedAmount - user.withdrawn;
    }

    // This is a timed vesting contract
    //
    // Claimants can claim 100% of ther claim upon claimTime.
    //
    // Can be overriden in contracts that inherit from this one.
    function calculateUnlockedAmount(
        uint256 _totalAmount,
        uint256 _timestamp
    ) internal view virtual returns (uint256) {
        return _timestamp > claimTime ? _totalAmount : 0;
    }

    function totalAvailableAfter() public view virtual returns (uint256) {
        return claimTime;
    }

    function withdrawRewardAmount() external onlyOwner {
        rewardToken.safeTransfer(
            msg.sender,
            rewardToken.balanceOf(address(this)) - totalRewards
        );
    }

    function emergencyWithdrawToken(ERC20 tokenAddress) external onlyOwner {
        tokenAddress.safeTransfer(
            msg.sender,
            tokenAddress.balanceOf(address(this))
        );
    }
}
// solhint-enable not-rely-on-time