// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";
import {IFireCatVault} from "../src/interfaces/IFireCatVault.sol";
import {IFireCatYieldBoots} from "../src/interfaces/IFireCatYieldBoots.sol";
import {IFireCatInspire} from "../src/interfaces/IFireCatInspire.sol";
import {FireCatTriggerStorage} from "../src/storages/FireCatTriggerStorage.sol";
import {FireCatTransfer} from "../src/utils/FireCatTransfer.sol";
import {ModifyControl} from "../src/utils/ModifyControl.sol";

/**
 * @title FireCatYieldBoots contract
 * @notice main: stake, claim, topUP
 * @author FireCat Finance
 */
contract FireCatYieldBoots is IFireCatYieldBoots, ModifyControl, FireCatTransfer {
    IFireCatVault fireCatVault;
    FireCatTriggerStorage fireCatTriggerStorage;
    using SafeMathUpgradeable for uint256;

    event SetFireCatVault(address fireCatVault_);
    event SetCycleTime(uint256 cycleTime_);
    event SetStakeAmount(uint256 maxStakeAmount_, uint256 maxStakeTotalAmount_);
    event SetVaultRequireAmount(uint256 vaultRequireAmount_);
    event SetRewardRatePerToken(uint256 rewardRatePerToken_);
    event TopUp(address user_, uint256 amount_, uint256 totalSupplyNew_);
    event Staked(address user_, uint256 actualAddAmount_, uint256 totalStakedNew_);
    event Claimed(address user_, uint256 actualClaimedAmount_, uint256 claimed_);

    address public rewardToken;
    address public stakeToken;    
    uint256 public cycleTime;
    uint256 public totalUser;
    uint256 public maxStakeAmount;
    uint256 public maxStakeTotalAmount;
    uint256 public vaultRequireAmount;
    uint256 public rewardRatePerToken;

    struct userCycle {
        uint256 lastClaimedAt;
        uint256 startAt;
        uint256 expiredAt;
        uint256 staked;
        uint256 claimed;
        uint256 totalYield;
        uint256 yieldPerSecond;
    }
   
    mapping(address => bool) public isMarked;
    mapping(address => userCycle) public userCycleMap;

    /**
    * @dev the total yield amount which is alread exists in the contract.
    */
    uint256 private _totalSupply;

    /**
    * @dev the total staked amount which is alread exists in the contract.
    */
    uint256 private _totalStaked;

    /**
    * @dev the total claimed amount which is already transfer from this contract.
    */
    uint256 private _totalClaimed;

    /**
    * @dev the staked amount of user.
    */
    mapping(address => uint256) private _staked;

    /**
    * @dev the claimed amount of user.
    */
    mapping(address => uint256) private _claimed;

    // update: share reawrd to fireCatInspire contract
    address public fireCatInspire;
    event SetFireCatInspire(address fireCatInspire_);

    function initialize(address rewardToken_, address stakeToken_) initializer public {
        rewardToken = rewardToken_;
        stakeToken = stakeToken_;
        __AccessControl_init();
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @inheritdoc IFireCatYieldBoots
    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    /// @inheritdoc IFireCatYieldBoots
    function totalClaimed() public view returns (uint256) {
        return _totalClaimed;
    }

    /// @inheritdoc IFireCatYieldBoots
    function rewardRate(uint256 amount_) public view returns (uint256) {
        // amount_ * rewardRatePerToken / 1e18
        return rewardRatePerToken.mul(amount_).div(1e18);
    }

    /// @inheritdoc IFireCatYieldBoots
    function yieldOf(uint256 amount_) public view returns (uint256) {
        // amount_ + amount_ * rewardRate(amount_) / 1e18
        return amount_.add(amount_.mul(rewardRate(amount_)).div(1e18));
    }

    /// @inheritdoc IFireCatYieldBoots
    function stakedOf(address user_) public view returns (uint256) {
        return _staked[user_];
    }

    /// @inheritdoc IFireCatYieldBoots
    function claimedOf(address user_) public view returns (uint256) {
        return _claimed[user_];
    }

    /// @inheritdoc IFireCatYieldBoots
    function isStakeable(address user_, uint256 amount_) public view returns (bool) {
        uint256 tokneId = fireCatVault.tokenIdOf(user_);
        if (tokneId == 0) {
            return false;
        } 

        // User must stake some Cakes in FireCatVault
        if (fireCatTriggerStorage.staked(tokneId) < vaultRequireAmount) {
            return false;
        }
            
        userCycle memory cycle = userCycleMap[user_];
        return amount_ >= 1e18 && _staked[user_].add(amount_) <= maxStakeTotalAmount && amount_ <= maxStakeAmount;
    }

    /// @inheritdoc IFireCatYieldBoots
    function reviewOf(address user_) public view returns (uint256, uint256, uint256, uint256) {
        userCycle memory cycle = userCycleMap[user_];
        uint256 availableClaim;
        uint256 lockedClaim;

        if (block.timestamp >= cycle.expiredAt) {
            availableClaim = cycle.totalYield - cycle.claimed;
            lockedClaim = 0;
        } else {
            availableClaim = cycle.yieldPerSecond * (block.timestamp - cycle.lastClaimedAt);
            lockedClaim = cycle.totalYield - cycle.claimed - availableClaim;
        }

        return (availableClaim, lockedClaim, cycle.claimed, cycle.totalYield);
    }

    function _markUser(address user_, uint256 amount_) internal {
        if (!isMarked[user_]) {
            isMarked[user_] = true;
            totalUser += 1;
        }
    }

    function _updateUserCycleClaimed(address user_, uint256 claimed_) internal {
        userCycle storage cycle = userCycleMap[user_];
        cycle.claimed = claimed_;
        cycle.lastClaimedAt = block.timestamp;
    }

    function _updateUserCycle(address user_, uint256 staked_, uint256 addYield_) internal {
        userCycle storage cycle = userCycleMap[user_];
        cycle.lastClaimedAt = block.timestamp;
        cycle.startAt = block.timestamp;
        cycle.expiredAt = block.timestamp + cycleTime;
        cycle.staked = cycle.staked.add(staked_);
        cycle.totalYield = cycle.totalYield.add(addYield_);
        cycle.yieldPerSecond = (cycle.totalYield.sub(cycle.claimed)).div(cycleTime);
    }

    function _emptyUserCycle(address user_) internal {
        userCycleMap[user_] = userCycle(0, 0, 0, 0, 0, 0, 0);
    }

    /// @inheritdoc IFireCatYieldBoots
    function setMaxStakeAmount(uint256 maxStakeAmount_, uint256 maxStakeTotalAmount_) external onlyRole(DATA_ADMIN) {
        maxStakeAmount  = maxStakeAmount_;
        maxStakeTotalAmount = maxStakeTotalAmount_;
        emit SetStakeAmount(maxStakeAmount_, maxStakeTotalAmount_);
    }

    /// @inheritdoc IFireCatYieldBoots
    function setVaultRequireAmount(uint256 vaultRequireAmount_) external onlyRole(DATA_ADMIN) {
        vaultRequireAmount = vaultRequireAmount_;
        emit SetVaultRequireAmount(vaultRequireAmount_);
    }

    /// @inheritdoc IFireCatYieldBoots
    function setCycleTime(uint256 cycleTime_) external onlyRole(DATA_ADMIN) {
        require(cycleTime_ != 0, "YIELD:E04");
        cycleTime = cycleTime_;
        emit SetCycleTime(cycleTime_);
    }

    /// @inheritdoc IFireCatYieldBoots
    function setRewardRatePerToken(uint256 rewardRatePerToken_) external onlyRole(DATA_ADMIN) {
        rewardRatePerToken = rewardRatePerToken_;
        emit SetRewardRatePerToken(rewardRatePerToken_);
    }

    /// @inheritdoc IFireCatYieldBoots
    function setFireCatVault(address fireCatVault_) external onlyRole(DATA_ADMIN) {
        fireCatVault = IFireCatVault(fireCatVault_);
        fireCatTriggerStorage = FireCatTriggerStorage(fireCatVault_);
        emit SetFireCatVault(fireCatVault_);
    }

    function setFireCatInspire(address fireCatInspire_) external onlyRole(DATA_ADMIN) {
        fireCatInspire = fireCatInspire_;
        emit SetFireCatInspire(fireCatInspire_);
    }

    /// @inheritdoc IFireCatYieldBoots
    function withdrawRemaining(address token, address to, uint256 amount) external nonReentrant onlyRole(SAFE_ADMIN) returns (uint256) {
        return withdraw(token, to, amount);
    }

    /// @inheritdoc IFireCatYieldBoots
    function topUp(uint256 addAmount) external onlyRole(SAFE_ADMIN) returns (uint256) {
        require(IERC20(rewardToken).balanceOf(msg.sender) >= addAmount, "YIELD:E01");

        uint256 actualAddAmount = doTransferIn(rewardToken, msg.sender, addAmount);
        // totalReservesNew + actualAddAmount
        uint256 totalSupplyNew = _totalSupply.add(actualAddAmount);

        /* Revert on overflow */
        require(totalSupplyNew > _totalSupply, "YIELD:E02");

        _totalSupply = totalSupplyNew;
        emit TopUp(msg.sender, actualAddAmount, totalSupplyNew);
        return actualAddAmount;
    }

    /// @inheritdoc IFireCatYieldBoots
    function stake(uint256 amount_) external beforeStake isBanned(msg.sender) nonReentrant returns (uint256) {
        require(isStakeable(msg.sender, amount_), "YIELD:E00");
        require(IERC20(stakeToken).balanceOf(msg.sender) >= amount_, "YIELD:E01");

        IERC20(stakeToken).approve(fireCatInspire, amount_);
        uint256 restAmount = IFireCatInspire(fireCatInspire).yieldBootsShare(msg.sender, amount_);
        burn(stakeToken, msg.sender, restAmount);
        uint256 totalStakedNew = _totalStaked.add(amount_);

        uint256 addYield = yieldOf(amount_);
        _updateUserCycle(msg.sender, amount_, addYield);
                
        require(totalStakedNew > _totalStaked, "YIELD:E02");

        _totalStaked = totalStakedNew;
        _staked[msg.sender] = _staked[msg.sender].add(amount_);
        emit Staked(msg.sender, amount_, totalStakedNew);
        return amount_;
    }

    /// @inheritdoc IFireCatYieldBoots
    function claim() external beforeClaim isBanned(msg.sender) nonReentrant returns (uint256) {
        (uint256 availableClaim, uint256 lockedClaim, uint256 userClaimed, uint256 userTotalClaim) = reviewOf(msg.sender);
        require(availableClaim > 0, "YIELD:E03");
        require(IERC20(rewardToken).balanceOf(address(this)) >= availableClaim, "YIELD:E01");

        uint256 actualClaimedAmount = doTransferOut(rewardToken, msg.sender, availableClaim);
        _claimed[msg.sender] = _claimed[msg.sender].add(actualClaimedAmount);
        _totalClaimed = _totalClaimed.add(actualClaimedAmount);

        uint256 claimed = userClaimed.add(actualClaimedAmount);
        if (claimed == userTotalClaim) {
            _emptyUserCycle(msg.sender);
        } else {
            _updateUserCycleClaimed(msg.sender, claimed);
        }

        emit Claimed(msg.sender, actualClaimedAmount, claimed);
        return actualClaimedAmount;
    }

}