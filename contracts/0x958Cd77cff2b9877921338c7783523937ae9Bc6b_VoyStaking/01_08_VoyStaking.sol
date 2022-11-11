// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VoyStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingAmount;
        uint256[] stakedAmount;
        uint256[] lastStakedTime;
    }

    struct UnStakeFee {
        uint256 minDays;
        uint256 feePercent;
    }

    UnStakeFee[] public unStakeFees;

    IERC20 public immutable voyToken;
    uint256 public lastRewardBlock;
    uint256 public accVOYPerShare;
    uint256 public rewardPerBlock;
    address public feeWallet;
    uint256 public harvestFee;

    uint256 public totalStakedAmount;

    uint256 private rewardBalance;

    mapping(address => UserInfo) public userInfo;

    event Stake(address indexed user, uint256 amount);
    event ReStake(address indexed user, uint256 amount);
    event DepositReward(address indexed owner, uint256 amount);
    event UnStake(address indexed user, uint256 amount, uint256 unStakeFee);
    event Harvest(address indexed user, uint256 amount, uint256 harvestFee);
    event SetFeeWallet(address indexed _feeWallet);
    event SetUnStakeFee(uint256 _index, uint256 _minDays, uint256 _feePercent);
    event AddUnStakeFee(uint256 _index, uint256 _minDays, uint256 _feePercent);
    event RemoveUnStakeFee(
        uint256 _index,
        uint256 _minDays,
        uint256 _feePercent
    );
    event SetHarvestFee(uint256 _harvestFee);

    constructor(
        IERC20 _voyToken,
        uint256 _rewardPerBlock,
        address _feeWallet
    ) {
        voyToken = _voyToken;
        rewardPerBlock = _rewardPerBlock;
        feeWallet = _feeWallet;
        init();
    }

    function init() private {
        UnStakeFee memory unStakeFee1 = UnStakeFee({
            minDays: 7,
            feePercent: 40
        });
        unStakeFees.push(unStakeFee1);

        UnStakeFee memory unStakeFee2 = UnStakeFee({
            minDays: 14,
            feePercent: 30
        });
        unStakeFees.push(unStakeFee2);

        UnStakeFee memory unStakeFee3 = UnStakeFee({
            minDays: 21,
            feePercent: 20
        });
        unStakeFees.push(unStakeFee3);

        UnStakeFee memory unStakeFee4 = UnStakeFee({
            minDays: 30,
            feePercent: 10
        });
        unStakeFees.push(unStakeFee4);
    }

    // Admin features
    function setFeeWallet(address _feeWallet) external onlyOwner {
        feeWallet = _feeWallet;
        emit SetFeeWallet(feeWallet);
    }

    function setUnStakeFee(
        uint256 _index,
        uint256 _minDays,
        uint256 _feePercent
    ) external onlyOwner {
        require(_index < unStakeFees.length, "setUnStakeFee: range out");
        require(_minDays > 0, "setUnStakeFee: minDays is 0");
        require(_feePercent <= 40, "setUnStakeFee: feePercent > 40");
        if (_index == 0) {
            require(
                _minDays < unStakeFees[1].minDays,
                "setUnStakeFee: minDays is error"
            );
            require(
                _feePercent > unStakeFees[1].feePercent,
                "setUnStakeFee: feePercent is error"
            );
        } else if (_index == unStakeFees.length - 1) {
            require(
                _minDays > unStakeFees[_index - 1].minDays,
                "setUnStakeFee: minDays is error"
            );
            require(
                _feePercent < unStakeFees[_index - 1].feePercent,
                "setUnStakeFee: feePercent is error"
            );
        } else {
            require(
                _minDays > unStakeFees[_index - 1].minDays &&
                    _minDays < unStakeFees[_index + 1].minDays,
                "setUnStakeFee: minDays is error"
            );
            require(
                _feePercent < unStakeFees[_index - 1].feePercent &&
                    _feePercent > unStakeFees[_index + 1].feePercent,
                "setUnStakeFee: feePercent is error"
            );
        }
        unStakeFees[_index].feePercent = _feePercent;
        unStakeFees[_index].minDays = _minDays;
        emit SetUnStakeFee(_index, _minDays, _feePercent);
    }

    function addUnStakeFee(uint256 _minDays, uint256 _feePercent)
        external
        onlyOwner
    {
        require(_minDays > 0, "addUnStakeFee: minDays is 0");
        require(_feePercent <= 40, "addUnStakeFee: feePercent > 40");
        require(
            _minDays > unStakeFees[unStakeFees.length - 1].minDays,
            "addUnStakeFee: minDays is error"
        );
        require(
            _feePercent < unStakeFees[unStakeFees.length - 1].feePercent,
            "addUnStakeFee: feePercent is error"
        );
        UnStakeFee memory unStakeFee = UnStakeFee({
            minDays: _minDays,
            feePercent: _feePercent
        });
        unStakeFees.push(unStakeFee);
        emit AddUnStakeFee(unStakeFees.length, _minDays, _feePercent);
    }

    function removeUnStakeFee(uint256 _index) external onlyOwner {
        require(_index < unStakeFees.length, "removeUnStakeFee: range out");
        uint256 _minDays = unStakeFees[_index].minDays;
        uint256 _feePercent = unStakeFees[_index].feePercent;
        for (uint256 i = _index; i < unStakeFees.length - 1; i++) {
            unStakeFees[i] = unStakeFees[i + 1];
        }
        unStakeFees.pop();
        emit RemoveUnStakeFee(_index, _minDays, _feePercent);
    }

    function setHarvestFee(uint256 _feePercent) external onlyOwner {
        require(_feePercent <= 40, "setHarvestFee: feePercent > 40");
        harvestFee = _feePercent;
        emit SetHarvestFee(_feePercent);
    }

    function depositReward(uint256 _amount) external onlyOwner {
        voyToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit DepositReward(msg.sender, _amount);
        rewardBalance = rewardBalance.add(_amount);
    }

    // Staker features
    function stake(uint256 _amount) external {
        require(rewardBalance > 0, "rewardBalance is 0");
        UserInfo storage user = userInfo[msg.sender];
        _updateStatus();
        updateUserStatus(msg.sender);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accVOYPerShare).div(1e12).sub(
                user.rewardDebt
            );
            user.pendingAmount = user.pendingAmount.add(pending);
        }
        voyToken.safeTransferFrom(msg.sender, address(this), _amount);
        totalStakedAmount = totalStakedAmount.add(_amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(accVOYPerShare).div(1e12);
        user.stakedAmount.push(_amount);
        user.lastStakedTime.push(block.timestamp);
        emit Stake(msg.sender, _amount);
    }

    function unStake(uint256 _amount) external returns (uint256) {
        uint256 unStakeFee;
        uint256 feePercent;
        uint256 stakedAmount;
        uint256 _stepAmount = _amount;
        uint256 i;
        uint256 j;
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "unStake: not good");
        _updateStatus();
        updateUserStatus(msg.sender);
        uint256 pending = user.amount.mul(accVOYPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (voyToken.balanceOf(address(this)) < pending) {
            pending = voyToken.balanceOf(address(this));
        }
        user.pendingAmount = user.pendingAmount.add(pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(accVOYPerShare).div(1e12);
        for (i = 0; i < user.stakedAmount.length; i++) {
            feePercent = _getUnStakeFeePercent(user.lastStakedTime[i]);
            stakedAmount = user.stakedAmount[i];
            if (_stepAmount >= stakedAmount) {
                _stepAmount = _stepAmount.sub(stakedAmount);
                unStakeFee = unStakeFee.add(
                    stakedAmount.mul(feePercent).div(100)
                );
            } else {
                stakedAmount = _stepAmount;
                unStakeFee = unStakeFee.add(
                    stakedAmount.mul(feePercent).div(100)
                );
                user.stakedAmount[i] = user.stakedAmount[i] - _stepAmount;
                break;
            }
        }
        uint256 amount = _amount.sub(unStakeFee);
        voyToken.safeTransfer(msg.sender, amount);
        voyToken.safeTransfer(feeWallet, unStakeFee);
        totalStakedAmount = totalStakedAmount.sub(_amount);
        emit UnStake(msg.sender, amount, unStakeFee);
        for (j = i; j < user.stakedAmount.length; j++) {
            user.stakedAmount[j - i] = user.stakedAmount[j];
            user.lastStakedTime[j - i] = user.lastStakedTime[j];
        }
        for (j = 0; j < i; j++) {
            user.stakedAmount.pop();
            user.lastStakedTime.pop();
        }
        return amount;
    }

    function updateUserStatus(address _user) public returns (bool) {
        UserInfo storage user = userInfo[_user];
        uint256 i;
        uint256 maxUnStakeFeeDays = getMaxUnStakeFeeDays();
        uint256 amount;
        for (i = 0; i < user.stakedAmount.length; i++) {
            if (
                user.lastStakedTime[i] >=
                block.timestamp - maxUnStakeFeeDays.mul(3600 * 24)
            ) break;
            amount = user.stakedAmount[i];
        }
        if (i > 1) {
            i--;
            for (uint256 j = i; j < user.stakedAmount.length; j++) {
                user.stakedAmount[j - i] = user.stakedAmount[j];
                user.lastStakedTime[j - i] = user.lastStakedTime[j];
            }
            for (uint256 j = 0; j < i; j++) {
                user.stakedAmount.pop();
                user.lastStakedTime.pop();
            }
            user.stakedAmount[0] = amount;
        }
        return true;
    }

    function getMaxUnStakeFeeDays() public view returns (uint256) {
        if (unStakeFees.length == 0) return 0;
        return unStakeFees[unStakeFees.length - 1].minDays;
    }

    function harvest() external returns (uint256) {
        uint256 rewardAmount = _getPending(msg.sender);
        UserInfo storage user = userInfo[msg.sender];
        uint256 _harvestFee = rewardAmount.mul(harvestFee).div(100);
        uint256 amount = rewardAmount - _harvestFee;
        if (voyToken.balanceOf(address(this)) < amount) {
            amount = voyToken.balanceOf(address(this));
        }

        voyToken.safeTransfer(msg.sender, amount);

        if (voyToken.balanceOf(address(this)) < _harvestFee) {
            _harvestFee = voyToken.balanceOf(address(this));
        }

        voyToken.safeTransfer(feeWallet, _harvestFee);
        emit Harvest(msg.sender, amount, _harvestFee);

        _updateStatus();
        user.pendingAmount = 0;
        user.rewardDebt = user.amount.mul(accVOYPerShare).div(1e12);
        return amount;
    }

    // General functions
    function getMultiplier(uint256 _from, uint256 _to)
        external
        pure
        returns (uint256)
    {
        return _getMultiplier(_from, _to);
    }

    function _getMultiplier(uint256 _from, uint256 _to)
        internal
        pure
        returns (uint256)
    {
        return _to.sub(_from);
    }

    function getPending(address _user) external view returns (uint256) {
        uint256 pending = _getPending(_user);
        uint256 _harvestFee = pending.mul(harvestFee).div(100);
        return pending - _harvestFee;
    }

    function _getPending(address _user) private view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 acc = accVOYPerShare;
        if (
            block.number > lastRewardBlock &&
            totalStakedAmount != 0 &&
            rewardBalance > 0
        ) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 reward = multiplier.mul(rewardPerBlock);
            if (rewardBalance < reward) {
                acc = acc.add(rewardBalance.mul(1e12).div(totalStakedAmount));
            } else {
                acc = acc.add(reward.mul(1e12).div(totalStakedAmount));
            }
        }
        return
            user.amount.mul(acc).div(1e12).sub(user.rewardDebt).add(
                user.pendingAmount
            );
    }

    function getRewardBalance() external view returns (uint256) {
        if (block.number > lastRewardBlock && totalStakedAmount != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 reward = multiplier.mul(rewardPerBlock);
            return rewardBalance.sub(reward);
        } else {
            return rewardBalance;
        }
    }

    function _updateStatus() private {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (totalStakedAmount == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 reward = multiplier.mul(rewardPerBlock);
        if (rewardBalance == 0) {
            lastRewardBlock = block.number;
            return;
        }
        if (rewardBalance < reward) {
            accVOYPerShare = accVOYPerShare.add(
                rewardBalance.mul(1e12).div(totalStakedAmount)
            );
            rewardBalance = 0;
        } else {
            rewardBalance = rewardBalance.sub(reward);
            accVOYPerShare = accVOYPerShare.add(
                reward.mul(1e12).div(totalStakedAmount)
            );
        }
        lastRewardBlock = block.number;
    }

    function _getUnStakeFeePercent(uint256 _lastStakedTime)
        internal
        view
        returns (uint256)
    {
        if (block.timestamp > _lastStakedTime) return 100;
        for (uint256 i = 0; i < unStakeFees.length; i++) {
            if (
                unStakeFees[i].minDays.mul(3600 * 24) >=
                (block.timestamp - _lastStakedTime)
            ) {
                return unStakeFees[i].feePercent;
            }
        }
        return 0;
    }
}