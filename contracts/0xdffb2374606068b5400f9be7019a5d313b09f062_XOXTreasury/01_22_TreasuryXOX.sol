// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./libraries/TransferHelper.sol";

interface IXOXS {
    function mint(address _to, uint256 _amount) external;
}

contract XOXTreasury is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;

    /* ========== EVENTS ========== */
    event PreSale(
        address indexed buyer,
        address indexed ref,
        uint256 amountBuyer,
        uint256 amountRef,
        uint256 round
    );
    event SwapUSDToXOX(
        address indexed buyer,
        address indexed ref,
        uint256 amount
    );
    event SeedSale(address indexed investor, uint256 amount);
    event ClaimReferral(address indexed user, uint256 amount);
    event ClaimFarmingReward(address indexed user, uint256 amount);
    event ChangeAPYFarming(uint256 apy);

    // Info of each user stake in farm.
    struct UserInfo {
        // referal
        uint256 point;
        uint256[] historyClaim;
        // farm
        uint256 amount;
        uint256 reward;
        uint256 lastBLockUpdated;
        uint256 rewardDebt; // Reward debt
    }
    uint256 public TOTAL_BLOCK_IN_YEAR;
    uint256 public constant BASE_APY = 100;
    uint256 public constant BASE_REWARD = 10;
    uint256 public constant BASE_ACC_PER_SHARE = 1e12;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");
    bytes32 public constant SALE_ROLE = keccak256("SALE_ROLE");
    // The USD TOKEN!
    ERC20 public usd;
    address public xoxs;

    // Info of each user
    mapping(address => UserInfo) public userInfo;

    // APY
    uint256 public apy;

    // Info of pool.
    struct PoolInfo {
        uint256 lastRewardBlock; // Last block number that XOXs distribution occurs.
        uint256 accXOXPerShare; // Accumulated XOXs per share, times 1e12. See below.
    }

    PoolInfo public pool;

    uint256[] public levelReward;
    uint256[] public rewardByLevel;

    uint256 public levelLength;
    bool public isActiveFarming;

    /* ========== CONSTRUCTOR ========== */
    function initialize(
        ERC20 usd_,
        address xoxs_,
        uint256 totalBlockYear_,
        uint256 apy_,
        uint256[] memory levelReward_,
        uint256[] memory rewardByLevel_,
        address gnosisAdmin_,
        uint256 blockActiveFarming_
    ) public initializer {
        __AccessControl_init();
        _grantRole(
            DEFAULT_ADMIN_ROLE,
            gnosisAdmin_
        );
        _grantRole(ADMIN_ROLE, gnosisAdmin_);
        _grantRole(ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ROUTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(SALE_ROLE, ADMIN_ROLE);
        usd = usd_;
        xoxs = xoxs_;
        TOTAL_BLOCK_IN_YEAR = totalBlockYear_;
        apy = apy_;
        levelReward = levelReward_;
        rewardByLevel = rewardByLevel_;
        levelLength = 11;
        isActiveFarming = true;
        pool.lastRewardBlock = blockActiveFarming_;
    }

    function setApy(uint256 apy_) external onlyRole(ADMIN_ROLE) {
        require(apy_ >= 5, "XOX Treasury: Apy must be greater than 5");
        _updatePool();
        apy = apy_;
        emit ChangeAPYFarming(apy_);
    }

    function setReward(
        uint256[] memory levelReward_,
        uint256[] memory rewardByLevel_
    ) external onlyRole(ADMIN_ROLE) {
        require(
            levelReward_.length == rewardByLevel_.length,
            "XOX Treasury: Invalid reward length"
        );
        require(levelReward_.length > 0, "XOX Treasury: Invalid reward length");
        levelReward = levelReward_;
        rewardByLevel = rewardByLevel_;
        levelLength = levelReward_.length;
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (!isActiveFarming) return 0;
        uint256 accXOXPerShare = pool.accXOXPerShare;
        if (block.number > pool.lastRewardBlock) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 xoxsReward = multiplier.mul(apy).div(BASE_APY);
            accXOXPerShare = accXOXPerShare.add(
                xoxsReward.mul(BASE_ACC_PER_SHARE).div(TOTAL_BLOCK_IN_YEAR)
            );
        }
        return user.amount.mul(accXOXPerShare).div(1e12).sub(user.rewardDebt);
    }

    function swapUSDtoXOX(
        address from,
        address ref,
        uint256 amount
    ) external onlyRole(ROUTER_ROLE) {
        UserInfo storage buyer = userInfo[from];
        if (ref != address(0)) {
            UserInfo storage reffer = userInfo[ref];
            // logic update refferal
            uint256 point = amount.div(20);
            buyer.point = buyer.point.add(point);
            reffer.point = reffer.point.add(point);
        }
        _updatePool();
        // logic update farming
        _updateFarmingAccount(from, amount.div(10));
        IXOXS(xoxs).mint(address(this), amount.div(10));
        emit SwapUSDToXOX(from, ref, amount);
    }

    function preSaleXOX(
        address from,
        address ref,
        uint256 amount,
        uint256 rewardPercent,
        uint256 round
    ) external onlyRole(SALE_ROLE) returns (uint256) {
        uint256 amountBonus = 0;
        uint256 amountRef = 0;
        _updatePool();
        if (ref != address(0)) {
            // logic update refferal
            amountRef = amount.mul(3).div(100);
            // logic update farming
            _updateFarmingAccount(ref, amountRef);
            amountBonus = amount.mul(2).div(100);
        }
        amountBonus = amountBonus.add(amount.mul(rewardPercent).div(100));
        // logic update farming
        _updateFarmingAccount(from, amountBonus);
        // mint XOXS
        IXOXS(xoxs).mint(address(this), amountBonus.add(amountRef));
        emit PreSale(from, ref, amountBonus, amountRef, round);
        return amountBonus;
    }

    function seedSale(uint256 amount) external onlyRole(SALE_ROLE) {
        _updatePool();
        // logic update farming
        _updateFarmingAccount(tx.origin, amount);
        // mint XOXS
        IXOXS(xoxs).mint(address(this), amount);
        emit SeedSale(tx.origin, amount);
    }

    function airDrop(
        address[] calldata addrArr,
        uint256[] calldata amountArr
    ) external onlyRole(ADMIN_ROLE) {
        require(
            addrArr.length == amountArr.length,
            "not match address with amount"
        );
        _updatePool();
        for (uint256 i; i < addrArr.length; i++) {
            // logic update farming
            _updateFarmingAccount(addrArr[i], amountArr[i]);
            // mint XOXS
            IXOXS(xoxs).mint(address(this), amountArr[i]);
        }
    }

    function claimFarmingReward(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(_amount > 0, "XOX Treasury: Claim amount invalid");
        _updatePool();
        uint256 rewardPending = user
            .amount
            .mul(pool.accXOXPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
        require(
            user.reward.add(rewardPending) >= _amount,
            "XOX Treasury: Claim amount exceed reward"
        );
        user.reward = user.reward.add(rewardPending).sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accXOXPerShare).div(1e12);
        user.lastBLockUpdated = block.number;
        safeUsdTransfer(msg.sender, _amount.mul(99).div(100));
        emit ClaimFarmingReward(msg.sender, _amount.mul(99).div(100));
    }

    function claimReferralByLevel(uint256 level) external {
        require(level < levelLength, "XOX Treasury: not fount point");
        uint256 levelPoint = levelReward[level];
        UserInfo storage user = userInfo[msg.sender];
        require(
            user.point >= levelPoint,
            "XOX Treasry: user donot engough points"
        );
        if (user.historyClaim.length > 0) {
            require(
                !checkIsClaimLevel(user, level),
                "XOX Treasry: user claimed this level"
            );
        }
        // claim
        uint256 rewardAfterFee = rewardByLevel[level].mul(99).div(100);
        safeUsdTransfer(msg.sender, rewardAfterFee);
        // update
        user.historyClaim.push(level);
        // log event
        emit ClaimReferral(msg.sender, rewardAfterFee);
    }

    function claimReferralAll() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 rewardPending = 0;
        for (uint256 i; i < levelLength; i++) {
            if (user.point >= levelReward[i]) {
                if (user.historyClaim.length > 0) {
                    if (checkIsClaimLevel(user, i)) continue;
                }
                rewardPending = rewardPending.add(rewardByLevel[i]);
                if (rewardByLevel[i] > 0) {
                    uint256 rewardAfterFee = rewardByLevel[i].mul(99).div(100);
                    emit ClaimReferral(msg.sender, rewardAfterFee);
                }
                // update claimed
                user.historyClaim.push(i);
            } else {
                break;
            }
        }
        require(rewardPending > 0, "XOX Treasry: rewardPending is zero");
        // claim
        safeUsdTransfer(msg.sender, rewardPending.mul(99).div(100));
    }

    function emergencyWithdraw(
        address _to,
        uint256 _amount
    ) external onlyRole(ADMIN_ROLE) {
        safeUsdTransfer(_to, _amount);
    }

    // Safe usd transfer function, just in case if rounding error causes farm to not have enough USD.
    function safeUsdTransfer(address _to, uint256 _amount) internal {
        uint256 usdBal = usd.balanceOf(address(this));
        require(_amount <= usdBal, "XOX Treasury: not enough reward to claim");
        usd.transfer(_to, _amount);
    }

    function pendingRewardByLevel(
        address user_,
        uint256 level_
    ) public view returns (uint256) {
        require(level_ < levelLength, "XOX Treasry: not fount point");
        uint256 levelPoint = levelReward[level_];
        UserInfo storage user = userInfo[user_];
        if (user.point < levelPoint) return 0;
        if (user.historyClaim.length > 0) {
            if (checkIsClaimLevel(user, level_)) return 0;
        }
        return rewardByLevel[level_];
    }

    function pendingRewardAll(address user_) public view returns (uint256) {
        UserInfo storage user = userInfo[user_];
        uint256 totalReward = 0;
        for (uint256 i; i < levelLength; i++) {
            if (user.point >= levelReward[i]) {
                if (user.historyClaim.length > 0) {
                    if (checkIsClaimLevel(user, i)) continue;
                }
                totalReward = totalReward.add(rewardByLevel[i]);
            } else {
                break;
            }
        }
        return totalReward;
    }

    function checkIsClaimLevel(
        UserInfo storage user,
        uint256 level
    ) internal view returns (bool) {
        for (uint256 j; j < user.historyClaim.length; j++) {
            if (user.historyClaim[j] == level) return true;
        }
        return false;
    }

    function ActiveFarming() external onlyRole(ADMIN_ROLE) {
        isActiveFarming = true;
        pool.lastRewardBlock = block.number;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) internal pure returns (uint256) {
        if (_from == 0) return 0;
        return _to.sub(_from);
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool() private {
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 xoxsReward = multiplier.mul(apy).div(BASE_APY);
        pool.accXOXPerShare = pool.accXOXPerShare.add(
            xoxsReward.mul(BASE_ACC_PER_SHARE).div(TOTAL_BLOCK_IN_YEAR)
        );
        pool.lastRewardBlock = block.number;
    }

    // Update user info farming
    function _updateFarmingAccount(address _acc, uint256 _amount) private {
        UserInfo storage user = userInfo[_acc];
        if (user.amount == 0) {
            user.lastBLockUpdated = block.number;
            user.amount = _amount;
            user.rewardDebt = user.amount.mul(pool.accXOXPerShare).div(1e12);
        }
        if (block.number > user.lastBLockUpdated) {
            uint256 rewardPending = user
                .amount
                .mul(pool.accXOXPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            user.amount = user.amount.add(_amount);
            user.reward = user.reward.add(rewardPending);
            user.rewardDebt = user.amount.mul(pool.accXOXPerShare).div(1e12);
            user.lastBLockUpdated = block.number;
        }
    }
}