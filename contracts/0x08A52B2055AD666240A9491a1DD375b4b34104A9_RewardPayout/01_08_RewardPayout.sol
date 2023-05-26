// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IERC20Burnable.sol";

contract RewardPayout is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Burnable;

    struct Reward {
        address user;
        uint256 amount;
    }

    struct Claim {
        address user;
        uint256 amount;
    }

    // period of time in seconds user must be rewarded proportionally
    uint256 public periodStart;
    uint256 public periodFinish;
    uint256 _term;

    // rewards of users
    mapping(address => uint256) public rewards;
    uint256 public totalRewards;

    // rewards that have been paid to each address
    mapping(address => uint256) public payouts;

    IERC20Burnable xcadToken;

    event RewardPaid(address indexed user, uint256 reward);
    event RewardUpdated(address indexed account, uint256 amount);

    constructor(
        address xcadToken_,
        uint256 periodStart_,
        uint256 periodFinish_
    ) {
        xcadToken = IERC20Burnable(xcadToken_);
        periodStart = periodStart_;
        periodFinish = periodFinish_;
        _term = periodFinish - periodStart;
        require(_term > 0, "RewardPayout: term must be greater than 0!");
    }

    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /**
     * @dev returns total amount has been rewarded to the user to the current time
     */
    function earned(address account) public view returns (uint256) {
        return
            rewards[account].mul(lastTimeRewardApplicable() - periodStart).div(
                _term
            );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setPeriodFinish(uint256 periodFinish_) external onlyOwner {
        periodFinish = periodFinish_;
        _term = periodFinish.sub(periodStart);
        require(_term > 0, "RewardList: term must be greater than 0!");
    }

    function addUsersRewards(Reward[] memory rewards_) external onlyOwner {
        for (uint256 i = 0; i < rewards_.length; i++) {
            Reward memory r = rewards_[i];
            totalRewards = totalRewards.add(r.amount).sub(rewards[r.user]);
            rewards[r.user] = r.amount;
        }
    }

    function addUsersPayouts(Claim[] memory claims_) external onlyOwner {
        for (uint256 i = 0; i < claims_.length; i++) {
            Claim memory c = claims_[i];
            require(
                c.amount <= rewards[c.user],
                "RewardPayout: payout is higher than reward!"
            );
            payouts[c.user] = c.amount;
        }
    }

    function emergencyAssetWithdrawal(address asset) external onlyOwner {
        IERC20Burnable token = IERC20Burnable(asset);
        token.safeTransfer(Ownable.owner(), token.balanceOf(address(this)));
    }

    /**
     * @dev calculates total amounts must be rewarded and transfers XCAD to the address
     */
    function getReward() public {
        uint256 _earned = earned(msg.sender);
        require(
            _earned <= rewards[msg.sender],
            "RewardPayout: earned is more than reward!"
        );
        require(
            _earned > payouts[msg.sender],
            "RewardPayout: earned is less or equal to already paid!"
        );

        uint256 reward = _earned.sub(payouts[msg.sender]);

        if (reward > 0) {
            payouts[msg.sender] = _earned;
            xcadToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function getRewardBurn() public {
        uint256 _earned = earned(msg.sender);
        require(
            _earned <= rewards[msg.sender],
            "RewardPayout: earned is more than reward!"
        );
        require(
            rewards[msg.sender] > 0,
            "RewardPayout: user has no rewards available!"
        );
        require(
            payouts[msg.sender] < rewards[msg.sender],
            "RewardPayout: user has no rewards left!"
        );

        uint256 _penalized = rewards[msg.sender].sub(_earned);
        uint256 reward = _earned
            .sub(payouts[msg.sender])
            .add(_penalized.div(1000).mul(405));
        
        xcadToken.burn(
            _penalized
            .div(1000)
            .mul(595)
        );

        payouts[msg.sender] = rewards[msg.sender];
        xcadToken.safeTransfer(msg.sender, reward);
        
        emit RewardPaid(msg.sender, reward);
    }
}