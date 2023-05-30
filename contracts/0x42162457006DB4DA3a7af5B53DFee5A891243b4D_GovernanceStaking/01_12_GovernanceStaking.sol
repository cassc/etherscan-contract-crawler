// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "../shared/interfaces/IMgcCampaign.sol";
import "../shared/interfaces/IMgc.sol";
import "../shared/libraries/SafeERC20.sol";
import "../shared/libraries/SafeMath.sol";
import "../shared/types/MetaVaultAC.sol";
import "../shared/interfaces/IgMVD.sol";
import "../shared/interfaces/IMVD.sol";
import "../shared/interfaces/IStaking.sol";

contract GovernanceStaking is IMgcCampaign, MetaVaultAC {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IMgc public mgc;

    struct UserInfo {
        uint256 staked;
        uint256 depositTime;
        uint256 nextClaimNumber;
    }

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 endTime; // timestamp
        uint256 rewardRate; // amount
    }

    Epoch public epoch;

    uint256 public minLockTime;
    uint256 public penaltyPercent; // 30% = * 30 / 100
    uint256 public rebasePeriod;
    uint256 public rebaseRewards; // Token (DAI, MATIC, or others) amount distributed each reabse

    bool public emergencyWithdrawEnabled;

    uint256 public campaignEndTime;

    uint256 public PRECISION = 1000000000;

    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => uint256) public rebases;

    address public mvd;
    address public gmvd;

    event ClaimReward(address indexed user, uint256 amount, bool stake);

    constructor(
        IMgc _mgc,
        uint256 _minLockTime,
        uint256 _penaltyPercent,
        uint256 _epochLength,
        uint256 _rebaseRewards,
        uint256 _campaignEndTime,
        address _authority
    ) MetaVaultAC(IMetaVaultAuthority(_authority)) {
        mgc = _mgc;
        minLockTime = _minLockTime;
        penaltyPercent = _penaltyPercent;
        rebaseRewards = _rebaseRewards;
        campaignEndTime = _campaignEndTime;
        epoch = Epoch({length: _epochLength, number: 0, endTime: block.timestamp.add(_epochLength), rewardRate: 0});
    }

    function setParam(
        uint256 _minLockTime,
        uint256 _penaltyPercent,
        uint256 _rebaseRewards,
        uint256 _campaignEndTime
    ) external onlyGovernor {
        minLockTime = _minLockTime;
        penaltyPercent = _penaltyPercent;
        rebaseRewards = _rebaseRewards;
        campaignEndTime = _campaignEndTime;
    }

    function setTokens(
        IMgc _mgc,
        address _mvd,
        address _gmvd
    ) external onlyGovernor {
        require(_mvd != address(0), "MVD invalid address");
        require(_gmvd != address(0), "gMVD invalid address");
        mgc = _mgc;

        mvd = _mvd;
        gmvd = _gmvd;
    }

    function setPrecision(uint256 _precision) external onlyGovernor {
        PRECISION = _precision;
    }

    function setEmergencyWithdraw(bool en) external onlyGovernor {
        emergencyWithdrawEnabled = en;
    }

    function isActive() external view returns (bool) {
        return block.timestamp < campaignEndTime;
    }

    function rebase() public {
        if (epoch.endTime < block.timestamp) {
            uint256 totalStaked = mgc.totalStaked();
            uint256 rewardRate = totalStaked > 0 ? rebaseRewards.mul(PRECISION).div(totalStaked) : 0;
            epoch.rewardRate = rewardRate;
            epoch.endTime = epoch.endTime.add(epoch.length);
            epoch.number++;
            rebases[epoch.number] = rewardRate;
            rebase();
        }
    }

    function getUnlockTime(address user) public view returns (uint256) {
        return userInfo[user].depositTime + minLockTime;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "MGC: invalid deposit amount");
        require(campaignEndTime > block.timestamp, "MGC: ended");
        claim();

        IERC20(mgc.mvd()).safeTransferFrom(msg.sender, address(this), amount);

        _deposit(amount);
    }

    function _deposit(uint256 amount) private {
        UserInfo storage user = userInfo[msg.sender];
        user.depositTime = block.timestamp;
        user.nextClaimNumber = epoch.number + 1;
        user.staked += amount;

        mgc.updateDeposit(amount);
        IgMVD(gmvd).mint(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }

    function withdraw() external {
        require(userInfo[msg.sender].staked > 0, "MGC: nothing to withdraw");
        UserInfo storage user = userInfo[msg.sender];
        rebase();
        mgc.updateWithdraw(user.staked);

        if (getUnlockTime(msg.sender) < block.timestamp) {
            claim();
        } else {
            user.nextClaimNumber = epoch.number + 1;
            uint256 penalty = user.staked.mul(penaltyPercent).div(100);

            IMVD(mvd).burn(penalty);
            IgMVD(gmvd).burn(msg.sender, penalty);

            user.staked = user.staked.sub(penalty);
        }

        IERC20(mgc.mvd()).safeTransfer(msg.sender, user.staked);
        IgMVD(gmvd).burn(msg.sender, user.staked);

        emit Withdraw(msg.sender, user.staked);
        user.staked = 0;
    }

    function emergencyWithdraw() external {
        require(emergencyWithdrawEnabled, "MGC: emergencyWithdraw is unavailable");
        uint256 staked = userInfo[msg.sender].staked;
        IERC20(mgc.mvd()).safeTransfer(msg.sender, staked);
        userInfo[msg.sender].staked = 0;
        emit Withdraw(msg.sender, staked);
    }

    function getReward(address user) public view returns (uint256, uint256) {
        uint256 staked = userInfo[user].staked;
        uint256 nextClaimNumber = userInfo[user].nextClaimNumber;
        if (staked == 0) {
            return (0, nextClaimNumber);
        }
        uint256 currentBlock = block.timestamp > campaignEndTime ? campaignEndTime : block.timestamp;
        if (nextClaimNumber > currentBlock) {
            return (0, nextClaimNumber);
        }

        uint256 _totalReward;
        for (uint256 index = nextClaimNumber; index <= epoch.number; index++) {
            uint256 _rewardRate = rebases[index];
            uint256 _reward = _rewardRate.mul(staked).div(PRECISION);
            _totalReward = _totalReward.add(_reward);
        }

        return (_totalReward, epoch.number + 1);
    }

    function claim() public {
        rebase();
        (uint256 reward, uint256 nextClaimNumber) = getReward(msg.sender);
        if (reward > 0) {
            userInfo[msg.sender].nextClaimNumber = nextClaimNumber;
            mgc.sendReward(msg.sender, msg.sender, reward);
            emit ClaimReward(msg.sender, reward, false);
        }
    }
}