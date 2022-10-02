// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IFireCatIssuePool} from "../src/interfaces/IFireCatIssuePool.sol";
import {IFireCatVault} from "../src/interfaces/IFireCatVault.sol";
import {IFireCatNFT} from "../src/interfaces/IFireCatNFT.sol";
import {IFireCatNFTStake} from "../src/interfaces/IFireCatNFTStake.sol";
import {FireCatIssueStorages} from "../src/storages/FireCatIssueStorages.sol";
import {FireCatIssueEvents} from "../src/events/FireCatIssueEvents.sol";
import {FireCatTransfer} from "../src/utils/FireCatTransfer.sol";
import {ModifyControl} from "../src/utils/ModifyControl.sol";

/**
 * @title FireCat's FireCatIssuePool contract
 * @notice main: stake, withdrawn, harvest, claim
 * @author FireCat Finance
 */
contract FireCatIssuePool is IFireCatIssuePool, FireCatIssueStorages, FireCatIssueEvents, FireCatTransfer, ModifyControl {
    using SafeMath for uint256;

    /* ========== CONSTRUCTOR ========== */

    function initialize(address _rewardsToken, address fireCatNFT_, address fireCatNFTStake_) initializer public {
        lockTime = 1;
        fireCatNFT = fireCatNFT_;
        fireCatNFTStake = fireCatNFTStake_;
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        rewardsToken = _rewardsToken;
    }

    modifier updateReward(uint256 tokenId_) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = Math.max(block.timestamp, lastUpdateTime);
        if (tokenId_ != 0) {
            rewards[tokenId_] = earned(tokenId_);
            userRewardPerTokenPaid[tokenId_] = rewardPerTokenStored;
        }
        _;
    }

    /// @inheritdoc IFireCatIssuePool
    function totalEarnings() public view returns (uint256) {
        // rewardPerToken * totalStaked
        return rewardPerToken().mul(totalStaked).div(1e18);
    }

    /// @inheritdoc IFireCatIssuePool
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0 || block.timestamp <= lastUpdateTime) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            block.timestamp.sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalStaked)
        );
    }

    /// @inheritdoc IFireCatIssuePool
    function earned(uint256 tokenId_) public view returns (uint256) {
        uint256 userEarned = (staked[tokenId_].mul(rewardPerToken().sub(userRewardPerTokenPaid[tokenId_])).div(1e18));
        return userEarned.add(rewards[tokenId_]);
    }

    /// @inheritdoc IFireCatIssuePool
    function userAward(address account_) public view returns (uint256){
        UserPledge memory userData_ = userData[account_];
        if (userData_.startTime <= 0) {
            return 0;
        }
        // numberOfRewardsPerSecond * (block.timestamp - lastTime) + generateQuantity
        uint256 pendingTime = Math.min(block.timestamp, userData_.enderTime).sub(userData_.lastTime);
        return userData_.numberOfRewardsPerSecond.mul(pendingTime).add(userData_.generateQuantity);
    }

    /// @inheritdoc IFireCatIssuePool
    function reviewOf(address user_) public view returns (uint256, uint256, uint256) {
        UserPledge memory userData_ = userData[user_];
        return (
            userAward(user_),  // availableClaim
            claimed[user_],  // claimed
            userData_.pledgeTotal  // locked
        );
    }

    /// @inheritdoc IFireCatIssuePool
    function issueUserData(uint256 tokenId_) external view returns (uint256, uint256){
        return
        (earned(tokenId_),
        received[tokenId_]);
    }

    function _claimInternal(address to_, uint256 amount_) internal returns (uint256) {
        uint256 actualClaimedAmount = doTransferOut(rewardsToken, to_, amount_);
        uint256 totalClaimedNew = totalClaimed.add(actualClaimedAmount);
        require(totalClaimedNew > totalClaimed, "POOL:E05");
        totalClaimed = totalClaimedNew;
        claimed[to_] = claimed[to_].add(actualClaimedAmount);
        emit IssueClaimed(to_, actualClaimedAmount, totalClaimedNew);
        return actualClaimedAmount;
    }

    function _harvest(address user_, uint256 tokenId_, uint256 reward_) internal {
        uint256 blockTimestamp = block.timestamp;
        UserPledge storage userData_ = userData[user_];
        uint256 generateQuantity = userData_.generateQuantity;
        userData_.generateQuantity = userAward(user_);
        userData_.startTime = blockTimestamp;
        userData_.enderTime = blockTimestamp.add(lockTime);
        userData_.lastTime = blockTimestamp;
        userData_.pledgeTotal = (userData_.pledgeTotal.add(reward_)).sub(userData_.generateQuantity.sub(generateQuantity));
        userData_.numberOfRewardsPerSecond = userData_.pledgeTotal.div(lockTime);
        received[tokenId_] = received[tokenId_].add(reward_);

        emit UserHarvest(user_, tokenId_, rewardsToken, reward_);
    }

    function setFireCatNFTStake(address fireCatNFTStake_) external onlyRole(DATA_ADMIN) {
        fireCatNFTStake = fireCatNFTStake_;
        emit SetFireCatNFTStake(fireCatNFTStake_);
    }

    /// @inheritdoc IFireCatIssuePool
    function setRewardRate(uint256 startingTime_, uint256 rewardRate_) external updateReward(0) onlyRole(DATA_ADMIN) {
        rewardRate = rewardRate_;
        if (startingTime_ > 0) {
            lastUpdateTime = startingTime_;
            poolStartTime = startingTime_;
        }

        emit SetRewardRate(rewardRate_);
    }

    /// @inheritdoc IFireCatIssuePool
    function setLockTime(uint256 newLockTime_) external onlyRole(DATA_ADMIN) {
        require(newLockTime_ != 0, "POOL:E02");
        lockTime = newLockTime_;
        emit SetLockTime(newLockTime_);
    }

    /// @inheritdoc IFireCatIssuePool
    function claimTokens(address token, address to, uint256 amount) external nonReentrant onlyRole(SAFE_ADMIN) {
        if (amount > 0) {
            if (token == address(0)) {
                //payable(to).transfer(amount);
                //require(payable(to).send(amount),"MFTP:E6");
                (bool res,) = to.call{value : amount}("");
                require(res, "POOL:E03");
            } else {
                withdraw(token, to, amount);
            }
        }
    }

    /// @inheritdoc IFireCatIssuePool
    function topUp(uint256 addAmount) external nonReentrant onlyRole(SAFE_ADMIN) returns (uint256) {
        require(IERC20(rewardsToken).balanceOf(msg.sender) >= addAmount, "POOL:E04");

        uint256 actualAddAmount = doTransferIn(rewardsToken, msg.sender, addAmount);
        uint256 totalSupplyNew = totalSupply.add(actualAddAmount);

        /* Revert on overflow */
        require(totalSupplyNew > totalSupply, "POOL:E05");

        totalSupply = totalSupplyNew;
        emit TopUp(msg.sender, actualAddAmount, totalSupplyNew);
        return actualAddAmount;
    }

    /// @inheritdoc IFireCatIssuePool
    function stake(uint256 tokenId_, uint256 amount_) external nonReentrant updateReward(tokenId_) onlyRole(FIRECAT_VAULT) {
        require(amount_ > 0, "POOL:E00");
        totalStaked = totalStaked.add(amount_);
        staked[tokenId_] = staked[tokenId_].add(amount_);

        emit IssueStaked(tokenId_, amount_);
    }

    /// @inheritdoc IFireCatIssuePool
    function withdrawn(address user_, uint256 tokenId_, uint256 amount_) external nonReentrant updateReward(tokenId_) onlyRole(FIRECAT_VAULT) {
        require(amount_ > 0, "POOL:E00");
        totalStaked = totalStaked.sub(amount_);
        staked[tokenId_] = staked[tokenId_].sub(amount_);

        uint256 reward = rewards[tokenId_];
        rewards[tokenId_] = 0;
        _harvest(user_, tokenId_, reward);

        emit Withdrawn(user_, tokenId_, amount_);
    }

    /// @inheritdoc IFireCatIssuePool
    function harvest(uint256 tokenId_) external nonReentrant updateReward(tokenId_) {
        address tokenOwner = IFireCatNFT(fireCatNFT).ownerOf(tokenId_);
        if (tokenOwner == fireCatNFTStake) {
            // nft staked in fireCatNFTStake
            uint256 stakedTokenId = IFireCatNFTStake(fireCatNFTStake).stakedOf(msg.sender);
            require(stakedTokenId == tokenId_, "VAULT:E02");
        } else {
            // nft not staked in fireCatNFTStake, someone own the nft
            require(msg.sender == tokenOwner, "VAULT:E02");
        }

        uint256 reward = rewards[tokenId_];
        require(reward >= 10 ** 12, "POOL:E01");
        rewards[tokenId_] = 0;
        _harvest(_msgSender(), tokenId_, reward);
    }

    /// @inheritdoc IFireCatIssuePool
    function claim() external beforeClaim isBanned(msg.sender) nonReentrant {
        uint256 generateQuantity = userData[_msgSender()].generateQuantity;
        uint256 reward = userAward(_msgSender());
        userData[_msgSender()].lastTime = Math.min(block.timestamp, userData[_msgSender()].enderTime);
        userData[_msgSender()].generateQuantity = 0;
        block.timestamp >= userData[_msgSender()].enderTime ?
        userData[_msgSender()].pledgeTotal = 0 :
        userData[_msgSender()].pledgeTotal = (userData[_msgSender()].pledgeTotal.add(generateQuantity)).sub(reward);
        _claimInternal(_msgSender(), reward);
    }

}