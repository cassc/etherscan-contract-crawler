// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;
/**
 * @title esLBRMiner is a stripped down version of Synthetix StakingRewards.sol, to reward esLBR to EUSD minters.
 * Differences from the original contract,
 * - Get `totalStaked` from totalSupply() in contract EUSD.
 * - Get `stakedOf(user)` from getBorrowedOf(user) in contract EUSD.
 * - When an address borrowed EUSD amount changes, call the refreshReward method to update rewards to be claimed.
 */

import "./ILybra.sol";
import "./Ownable.sol";
import "./IesLBR.sol";

interface Ihelper {
    function getCollateralRate(address user) external view returns (uint256);
}

interface IesLBRBoost {
    function getUserBoost(
        address user,
        uint256 userUpdatedAt,
        uint256 finishAt
    ) external view returns (uint256);

    function getUnlockTime(address user)
        external
        view
        returns (uint256 unlockTime);
}

contract esLBRMinerV2 is Ownable {
    ILybra public immutable lybra;
    Ihelper public helper;
    IesLBRBoost public esLBRBoost;
    address public esLBR;

    // Duration of rewards to be paid out (in seconds)
    uint256 public duration = 2_592_000;
    // Timestamp of when the rewards finish
    uint256 public finishAt;
    // Minimum of last updated time and reward finish time
    uint256 public updatedAt;
    // Reward to be paid out per second
    uint256 public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint256 public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userUpdatedAt;
    uint256 public extraRate = 50 * 1e18;
    // Currently, the official rebase time for Lido is between 12PM to 13PM UTC.
    uint256 public lockdownPeriod = 12 hours;

    constructor(
        address _lybra,
        address _helper,
        address _boost
    ) {
        lybra = ILybra(_lybra);
        helper = Ihelper(_helper);
        esLBRBoost = IesLBRBoost(_boost);
    }

    function setEsLBR(address _eslbr) external onlyOwner {
        esLBR = _eslbr;
    }

    function setExtraRate(uint256 rate) external onlyOwner {
        extraRate = rate;
    }

    function setLockdownPeriod(uint256 _time) external onlyOwner {
        lockdownPeriod = _time;
    }

    function setBoost(address _boost) external onlyOwner {
        esLBRBoost = IesLBRBoost(_boost);
    }

    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function totalStaked() internal view returns (uint256) {
        return lybra.totalSupply();
    }

    function stakedOf(address user) public view returns (uint256) {
        return lybra.getBorrowedOf(user);
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
            userUpdatedAt[_account] = block.timestamp;
        }

        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked() == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalStaked();
    }

    /**
     * @dev To limit the behavior of arbitrageurs who mint a large amount of eUSD after stETH rebase and before eUSD interest distribution to earn extra profit,
     * a 1-hour revert during stETH rebase is implemented to eliminate this issue.
     * If the user's collateral ratio is below safeCollateralRate, they are not subject to this restriction.
     */
    function pausedByLido(address _account) public view returns(bool) {
        uint256 collateralRate = helper.getCollateralRate(_account);
        return (block.timestamp - lockdownPeriod) % 1 days < 1 hours &&
            collateralRate >= lybra.safeCollateralRate();
    }

    /**
     * @notice Update user's claimable reward data and record the timestamp.
     */
    function refreshReward(address _account) external updateReward(_account) {
        if (
            pausedByLido(_account)
        ) {
            revert(
                "Minting and repaying functions of eUSD are temporarily disabled during stETH rebasing periods."
            );
        }
    }

    function getBoost(address _account) public view returns (uint256) {
        uint256 redemptionBoost;
        if (lybra.isRedemptionProvider(_account)) {
            redemptionBoost = extraRate;
        }
        return 100 * 1e18 + redemptionBoost + esLBRBoost.getUserBoost(
            _account,
            userUpdatedAt[_account],
            finishAt
        );
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((stakedOf(_account) *
                getBoost(_account) *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e38) +
            rewards[_account];
    }

    function getReward() external updateReward(msg.sender) {
        require(
            block.timestamp >= esLBRBoost.getUnlockTime(msg.sender),
            "Your lock-in period has not ended. You can't claim your esLBR now."
        );
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IesLBR(esLBR).mint(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 amount)
        external
        onlyOwner
        updateReward(address(0))
    {
        require(amount > 0, "amount = 0");
        if (block.timestamp >= finishAt) {
            rewardRate = amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) *
                rewardRate;
            rewardRate = (amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}