// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// contracts
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// libraries
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// interfaces
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "./interfaces/IFarmingRange.sol";

/**
 * @title FarmingRange
 * @notice Farming Range allows users to stake LP Tokens to receive various rewards
 * @custom:from Contract taken from the alpaca protocol, adapted to version 0.8.17 and modified with more functions
 * @custom:url https://github.com/alpaca-finance/bsc-alpaca-contract/blob/main/solidity/contracts/6.12/GrazingRange.sol
 */
contract FarmingRange is IFarmingRange, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(uint256 => RewardInfo[]) public campaignRewardInfo;

    CampaignInfo[] public campaignInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public rewardInfoLimit;
    address public immutable rewardManager;

    constructor(address _rewardManager) {
        rewardInfoLimit = 52;
        require(_rewardManager != address(0), "FarmingRange::constructor::Reward manager is not defined");
        rewardManager = _rewardManager;
    }

    /// @inheritdoc IFarmingRange
    function setRewardInfoLimit(uint256 _updatedRewardInfoLimit) external onlyOwner {
        rewardInfoLimit = _updatedRewardInfoLimit;
        emit SetRewardInfoLimit(rewardInfoLimit);
    }

    /// @inheritdoc IFarmingRange
    function addCampaignInfo(
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        uint256 _startBlock
    ) external virtual onlyOwner {
        require(_startBlock > block.number, "FarmingRange::addCampaignInfo::Start block should be in the future");
        campaignInfo.push(
            CampaignInfo({
                stakingToken: _stakingToken,
                rewardToken: _rewardToken,
                startBlock: _startBlock,
                lastRewardBlock: _startBlock,
                accRewardPerShare: 0,
                totalStaked: 0,
                totalRewards: 0
            })
        );
        emit AddCampaignInfo(campaignInfo.length - 1, _stakingToken, _rewardToken, _startBlock);
    }

    /// @inheritdoc IFarmingRange
    function addRewardInfo(
        uint256 _campaignID,
        uint256 _endBlock,
        uint256 _rewardPerBlock
    ) public virtual onlyOwner nonReentrant {
        RewardInfo[] storage rewardInfo = campaignRewardInfo[_campaignID];
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        require(
            rewardInfo.length < rewardInfoLimit,
            "FarmingRange::addRewardInfo::reward info length exceeds the limit"
        );
        require(
            rewardInfo.length == 0 || rewardInfo[rewardInfo.length - 1].endBlock >= block.number,
            "FarmingRange::addRewardInfo::reward period ended"
        );
        require(
            rewardInfo.length == 0 || rewardInfo[rewardInfo.length - 1].endBlock < _endBlock,
            "FarmingRange::addRewardInfo::bad new endblock"
        );
        uint256 _startBlock = rewardInfo.length == 0 ? campaign.startBlock : rewardInfo[rewardInfo.length - 1].endBlock;
        uint256 _blockRange = _endBlock - _startBlock;
        uint256 _totalRewards = _rewardPerBlock * _blockRange;
        campaign.totalRewards = campaign.totalRewards + _totalRewards;
        rewardInfo.push(RewardInfo({ endBlock: _endBlock, rewardPerBlock: _rewardPerBlock }));
        _transferFromWithAllowance(campaign.rewardToken, _totalRewards, _campaignID);
        emit AddRewardInfo(_campaignID, rewardInfo.length - 1, _endBlock, _rewardPerBlock);
    }

    /// @inheritdoc IFarmingRange
    function addRewardInfoMultiple(
        uint256 _campaignID,
        uint256[] calldata _endBlock,
        uint256[] calldata _rewardPerBlock
    ) external onlyOwner {
        require(_endBlock.length == _rewardPerBlock.length, "FarmingRange::addRewardMultiple::wrong parameters length");
        for (uint256 _i; _i != _endBlock.length; ) {
            addRewardInfo(_campaignID, _endBlock[_i], _rewardPerBlock[_i]);
            unchecked {
                ++_i;
            }
        }
    }

    /// @inheritdoc IFarmingRange
    function updateRewardInfo(
        uint256 _campaignID,
        uint256 _rewardIndex,
        uint256 _endBlock,
        uint256 _rewardPerBlock
    ) public virtual onlyOwner nonReentrant {
        RewardInfo[] storage rewardInfo = campaignRewardInfo[_campaignID];
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        RewardInfo storage selectedRewardInfo = rewardInfo[_rewardIndex];
        uint256 _previousEndBlock = selectedRewardInfo.endBlock;
        _updateCampaign(_campaignID);
        require(_previousEndBlock >= block.number, "FarmingRange::updateRewardInfo::reward period ended");
        if (_rewardIndex != 0) {
            require(
                rewardInfo[_rewardIndex - 1].endBlock < _endBlock,
                "FarmingRange::updateRewardInfo::bad new endblock"
            );
        }
        if (rewardInfo.length > _rewardIndex + 1) {
            require(
                _endBlock < rewardInfo[_rewardIndex + 1].endBlock,
                "FarmingRange::updateRewardInfo::reward period end is in next range"
            );
        }
        (bool _refund, uint256 _diff) = _updateRewardsDiff(
            _rewardIndex,
            _endBlock,
            _rewardPerBlock,
            rewardInfo,
            campaign,
            selectedRewardInfo
        );
        if (!_refund && _diff != 0) {
            _transferFromWithAllowance(campaign.rewardToken, _diff, _campaignID);
        }
        // If _endblock is changed, and if we have another range after the updated one,
        // we need to update rewardPerBlock to distribute on the next new range or we could run out of tokens
        if (_endBlock != _previousEndBlock && rewardInfo.length - 1 > _rewardIndex) {
            RewardInfo storage nextRewardInfo = rewardInfo[_rewardIndex + 1];
            uint256 _nextRewardInfoEndBlock = nextRewardInfo.endBlock;
            uint256 _initialBlockRange = _nextRewardInfoEndBlock - _previousEndBlock;
            uint256 _nextBlockRange = _nextRewardInfoEndBlock - _endBlock;
            uint256 _currentRewardPerBlock = nextRewardInfo.rewardPerBlock;
            uint256 _initialNextTotal = _initialBlockRange * _currentRewardPerBlock;
            _currentRewardPerBlock = (_currentRewardPerBlock * _initialBlockRange) / _nextBlockRange;
            uint256 _nextTotal = _nextBlockRange * _currentRewardPerBlock;
            nextRewardInfo.rewardPerBlock = _currentRewardPerBlock;
            if (_nextTotal < _initialNextTotal) {
                campaign.rewardToken.safeTransfer(rewardManager, _initialNextTotal - _nextTotal);
                campaign.totalRewards -= _initialNextTotal - _nextTotal;
            }
        }
        // UPDATE total
        campaign.totalRewards = _refund ? campaign.totalRewards - _diff : campaign.totalRewards + _diff;
        selectedRewardInfo.endBlock = _endBlock;
        selectedRewardInfo.rewardPerBlock = _rewardPerBlock;
        emit UpdateRewardInfo(_campaignID, _rewardIndex, _endBlock, _rewardPerBlock);
    }

    /// @inheritdoc IFarmingRange
    function updateRewardMultiple(
        uint256 _campaignID,
        uint256[] memory _rewardIndex,
        uint256[] memory _endBlock,
        uint256[] memory _rewardPerBlock
    ) public onlyOwner {
        require(
            _rewardIndex.length == _endBlock.length && _rewardIndex.length == _rewardPerBlock.length,
            "FarmingRange::updateRewardMultiple::wrong parameters length"
        );
        for (uint256 _i; _i != _rewardIndex.length; ) {
            updateRewardInfo(_campaignID, _rewardIndex[_i], _endBlock[_i], _rewardPerBlock[_i]);
            unchecked {
                ++_i;
            }
        }
    }

    /// @inheritdoc IFarmingRange
    function updateCampaignsRewards(
        uint256[] calldata _campaignID,
        uint256[][] calldata _rewardIndex,
        uint256[][] calldata _endBlock,
        uint256[][] calldata _rewardPerBlock
    ) external onlyOwner {
        require(
            _campaignID.length == _rewardIndex.length &&
                _rewardIndex.length == _endBlock.length &&
                _rewardIndex.length == _rewardPerBlock.length,
            "FarmingRange::updateCampaignsRewards::wrong rewardInfo length"
        );
        for (uint256 _i; _i != _campaignID.length; ) {
            updateRewardMultiple(_campaignID[_i], _rewardIndex[_i], _endBlock[_i], _rewardPerBlock[_i]);
            unchecked {
                ++_i;
            }
        }
    }

    /// @inheritdoc IFarmingRange
    function removeLastRewardInfo(uint256 _campaignID) external virtual onlyOwner {
        RewardInfo[] storage rewardInfo = campaignRewardInfo[_campaignID];
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        uint256 _rewardInfoLength = rewardInfo.length;
        require(_rewardInfoLength != 0, "FarmingRange::updateCampaignsRewards::no rewardInfoLen");
        RewardInfo storage lastRewardInfo = rewardInfo[_rewardInfoLength - 1];
        uint256 _lastRewardInfoEndBlock = lastRewardInfo.endBlock;
        require(_lastRewardInfoEndBlock > block.number, "FarmingRange::removeLastRewardInfo::reward period ended");
        _updateCampaign(_campaignID);
        if (lastRewardInfo.rewardPerBlock != 0) {
            (bool _refund, uint256 _diff) = _updateRewardsDiff(
                _rewardInfoLength - 1,
                _lastRewardInfoEndBlock,
                0,
                rewardInfo,
                campaign,
                lastRewardInfo
            );
            if (_refund) {
                campaign.totalRewards = campaign.totalRewards - _diff;
            }
        }
        rewardInfo.pop();
        emit RemoveRewardInfo(_campaignID, _rewardInfoLength - 1);
    }

    /// @inheritdoc IFarmingRange
    function rewardInfoLen(uint256 _campaignID) external view returns (uint256) {
        return campaignRewardInfo[_campaignID].length;
    }

    /// @inheritdoc IFarmingRange
    function campaignInfoLen() external view returns (uint256) {
        return campaignInfo.length;
    }

    /// @inheritdoc IFarmingRange
    function currentEndBlock(uint256 _campaignID) external view virtual returns (uint256) {
        return _endBlockOf(_campaignID, block.number);
    }

    /// @inheritdoc IFarmingRange
    function currentRewardPerBlock(uint256 _campaignID) external view virtual returns (uint256) {
        return _rewardPerBlockOf(_campaignID, block.number);
    }

    /// @inheritdoc IFarmingRange
    function getMultiplier(uint256 _from, uint256 _to, uint256 _endBlock) public pure returns (uint256) {
        if ((_from >= _endBlock) || (_from > _to)) {
            return 0;
        }
        if (_to <= _endBlock) {
            return _to - _from;
        }
        return _endBlock - _from;
    }

    /// @inheritdoc IFarmingRange
    function pendingReward(uint256 _campaignID, address _user) external view returns (uint256) {
        return
            _pendingReward(_campaignID, userInfo[_campaignID][_user].amount, userInfo[_campaignID][_user].rewardDebt);
    }

    /// @inheritdoc IFarmingRange
    function updateCampaign(uint256 _campaignID) external nonReentrant {
        _updateCampaign(_campaignID);
    }

    /// @inheritdoc IFarmingRange
    function massUpdateCampaigns() external nonReentrant {
        uint256 _length = campaignInfo.length;
        for (uint256 _i; _i != _length; ) {
            _updateCampaign(_i);
            unchecked {
                ++_i;
            }
        }
    }

    /// @inheritdoc IFarmingRange
    function deposit(uint256 _campaignID, uint256 _amount) public nonReentrant {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        UserInfo storage user = userInfo[_campaignID][msg.sender];
        _updateCampaign(_campaignID);
        if (user.amount != 0) {
            uint256 _pending = (user.amount * campaign.accRewardPerShare) / 1e20 - user.rewardDebt;
            if (_pending != 0) {
                campaign.rewardToken.safeTransfer(address(msg.sender), _pending);
            }
        }
        if (_amount != 0) {
            user.amount = user.amount + _amount;
            campaign.totalStaked = campaign.totalStaked + _amount;
            campaign.stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        }
        user.rewardDebt = (user.amount * campaign.accRewardPerShare) / (1e20);
        emit Deposit(msg.sender, _amount, _campaignID);
    }

    /// @inheritdoc IFarmingRange
    function depositWithPermit(
        uint256 _campaignID,
        uint256 _amount,
        bool _approveMax,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        SafeERC20.safePermit(
            IERC20Permit(address(campaignInfo[_campaignID].stakingToken)),
            msg.sender,
            address(this),
            _approveMax ? type(uint256).max : _amount,
            _deadline,
            _v,
            _r,
            _s
        );

        deposit(_campaignID, _amount);
    }

    /// @inheritdoc IFarmingRange
    function withdraw(uint256 _campaignID, uint256 _amount) external nonReentrant {
        _withdraw(_campaignID, _amount);
    }

    /// @inheritdoc IFarmingRange
    function harvest(uint256[] calldata _campaignIDs) external nonReentrant {
        for (uint256 _i; _i != _campaignIDs.length; ) {
            _withdraw(_campaignIDs[_i], 0);
            unchecked {
                ++_i;
            }
        }
    }

    /// @inheritdoc IFarmingRange
    function emergencyWithdraw(uint256 _campaignID) external nonReentrant {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        UserInfo storage user = userInfo[_campaignID][msg.sender];
        uint256 _amount = user.amount;
        campaign.totalStaked = campaign.totalStaked - _amount;
        user.amount = 0;
        user.rewardDebt = 0;
        campaign.stakingToken.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _amount, _campaignID);
    }

    /**
     * @notice function to trick the compilator to use safeTransferFrom in try catch
     * @param _token token to interact with
     * @param _from address who own token
     * @param _to address to transfer token
     * @param _amount quantity to be transferred
     */
    function attemptTransfer(IERC20 _token, address _from, address _to, uint256 _amount) external {
        require(msg.sender == address(this), "FarmingRange::attemptTransfer::Sender not farming"); // this function should be called only by this contract
        _token.safeTransferFrom(_from, _to, _amount);
    }

    /**
     * @notice return the endblock of the phase that contains _blockNumber
     * @param _campaignID the campaign id of the phases to check
     * @param _blockNumber the block number to check
     * @return the endblock of the phase that contains _blockNumber
     */
    function _endBlockOf(uint256 _campaignID, uint256 _blockNumber) internal view returns (uint256) {
        RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
        uint256 _len = rewardInfo.length;
        if (_len == 0) {
            return 0;
        }
        for (uint256 _i; _i != _len; ) {
            if (_blockNumber <= rewardInfo[_i].endBlock) {
                return rewardInfo[_i].endBlock;
            }
            unchecked {
                ++_i;
            }
        }
        /// @dev when couldn't find any reward info, it means that _blockNumber exceed endblock
        /// so return the latest reward info.
        return rewardInfo[_len - 1].endBlock;
    }

    /**
     * @notice return the rewardPerBlock of the phase that contains _blockNumber
     * @param _campaignID the campaign id of the phases to check
     * @param _blockNumber the block number to check
     * @return the rewardPerBlock of the phase that contains _blockNumber
     */
    function _rewardPerBlockOf(uint256 _campaignID, uint256 _blockNumber) internal view returns (uint256) {
        RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
        uint256 _len = rewardInfo.length;
        if (_len == 0) {
            return 0;
        }
        for (uint256 _i; _i != _len; ) {
            if (_blockNumber <= rewardInfo[_i].endBlock) {
                return rewardInfo[_i].rewardPerBlock;
            }
            unchecked {
                ++_i;
            }
        }
        /// @dev when couldn't find any reward info, it means that timestamp exceed endblock
        /// so return 0
        return 0;
    }

    /**
     * @notice in case of reward update, return reward diff and refund user if needed
     * @param _rewardIndex the number of the phase to update
     * @param _endBlock new endblock of the phase
     * @param _rewardPerBlock new rewardPerBlock of the phase
     * @param rewardInfo pointer on the array of rewardInfo in storage
     * @param campaign pointer on the campaign in storage
     * @param selectedRewardInfo pointer on the selectedRewardInfo in storage
     * @return refund_ boolean, true if user got refund
     * @return diff_ the reward difference
     */
    function _updateRewardsDiff(
        uint256 _rewardIndex,
        uint256 _endBlock,
        uint256 _rewardPerBlock,
        RewardInfo[] storage rewardInfo,
        CampaignInfo storage campaign,
        RewardInfo storage selectedRewardInfo
    ) internal virtual returns (bool refund_, uint256 diff_) {
        uint256 _previousStartBlock = _rewardIndex == 0 ? campaign.startBlock : rewardInfo[_rewardIndex - 1].endBlock;
        uint256 _newStartBlock = block.number > _previousStartBlock ? block.number : _previousStartBlock;
        uint256 _previousBlockRange = selectedRewardInfo.endBlock - _previousStartBlock;
        uint256 _newBlockRange = _endBlock - _newStartBlock;
        uint256 _selectedRewardPerBlock = selectedRewardInfo.rewardPerBlock;
        uint256 _accumulatedRewards = (_newStartBlock - _previousStartBlock) * _selectedRewardPerBlock;
        uint256 _previousTotalRewards = _selectedRewardPerBlock * _previousBlockRange;
        uint256 _totalRewards = _rewardPerBlock * _newBlockRange;
        refund_ = _previousTotalRewards > _totalRewards + _accumulatedRewards;
        diff_ = refund_
            ? _previousTotalRewards - _totalRewards - _accumulatedRewards
            : _totalRewards + _accumulatedRewards - _previousTotalRewards;
        if (refund_) {
            campaign.rewardToken.safeTransfer(rewardManager, diff_);
        }
    }

    /**
     * @notice transfer tokens from rewardManger to this contract.
     * @param _rewardToken to reward token to be transferred from the rewardManager to this contract
     * @param _amount qty to be transferred
     * @param _campaignID id of the campaign so the rewardManager can fetch the rewardToken address to transfer
     *
     * @dev in case of fail, not enough allowance is considered to be the reason, so we call resetAllowance(uint256) on
     * the reward manager (which will reset allowance to uint256.max) and we try again to transfer
     */
    function _transferFromWithAllowance(IERC20 _rewardToken, uint256 _amount, uint256 _campaignID) internal {
        try this.attemptTransfer(_rewardToken, rewardManager, address(this), _amount) {} catch {
            rewardManager.call(abi.encodeWithSignature("resetAllowance(uint256)", _campaignID));
            _rewardToken.safeTransferFrom(rewardManager, address(this), _amount);
        }
    }

    /**
     * @notice View function to retrieve pending Reward.
     * @param _campaignID pending reward of campaign id
     * @param _amount qty of staked token
     * @param _rewardDebt user info rewardDebt
     * @return pending rewards
     */
    function _pendingReward(
        uint256 _campaignID,
        uint256 _amount,
        uint256 _rewardDebt
    ) internal view virtual returns (uint256) {
        CampaignInfo memory _campaign = campaignInfo[_campaignID];
        RewardInfo[] memory _rewardInfo = campaignRewardInfo[_campaignID];
        uint256 _accRewardPerShare = _campaign.accRewardPerShare;

        if (block.number > _campaign.lastRewardBlock && _campaign.totalStaked != 0) {
            uint256 _cursor = _campaign.lastRewardBlock;
            for (uint256 _i; _i != _rewardInfo.length; ) {
                uint256 _multiplier = getMultiplier(_cursor, block.number, _rewardInfo[_i].endBlock);
                if (_multiplier != 0) {
                    _cursor = _rewardInfo[_i].endBlock;
                    _accRewardPerShare =
                        _accRewardPerShare +
                        ((_multiplier * _rewardInfo[_i].rewardPerBlock * 1e20) / _campaign.totalStaked);
                }
                unchecked {
                    ++_i;
                }
            }
        }
        return ((_amount * _accRewardPerShare) / 1e20) - _rewardDebt;
    }

    /**
     * @notice Update reward variables of the given campaign to be up-to-date.
     *         NOTE: All rewards relating to periods devoid of any depositors are sent back to the reward manager.
     * @param _campaignID campaign id
     */
    function _updateCampaign(uint256 _campaignID) internal virtual {
        require(campaignInfo.length > _campaignID, "FarmingRange::_updateCampaign::Campaign id not valid");
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        RewardInfo[] memory _rewardInfo = campaignRewardInfo[_campaignID];
        if (block.number <= campaign.lastRewardBlock) {
            return;
        }
        if (campaign.totalStaked == 0) {
            uint256 _amount;
            for (uint256 _i; _i != _rewardInfo.length; ) {
                if (_rewardInfo[_i].endBlock >= campaign.lastRewardBlock) {
                    uint256 _startBlock = _i != 0 ? _rewardInfo[_i - 1].endBlock : campaign.lastRewardBlock;
                    bool _lastRewardInfo = _rewardInfo[_i].endBlock > block.number;
                    uint256 _blockRange = (_lastRewardInfo ? block.number : _rewardInfo[_i].endBlock) -
                        (_startBlock > campaign.lastRewardBlock ? _startBlock : campaign.lastRewardBlock);
                    _amount += _rewardInfo[_i].rewardPerBlock * _blockRange;
                    if (_lastRewardInfo) {
                        break;
                    }
                }
                unchecked {
                    ++_i;
                }
            }

            if (_amount != 0) {
                campaign.rewardToken.safeTransfer(rewardManager, _amount);
            }

            campaign.lastRewardBlock = block.number;

            return;
        }
        /// @dev for each reward info
        for (uint256 _i; _i != _rewardInfo.length; ) {
            // @dev get multiplier based on current Block and rewardInfo's end block
            // multiplier will be a range of either (current block - campaign.lastRewardBlock)
            // or (reward info's endblock - campaign.lastRewardBlock) or 0
            uint256 _multiplier = getMultiplier(campaign.lastRewardBlock, block.number, _rewardInfo[_i].endBlock);
            if (_multiplier != 0) {
                // @dev if currentBlock exceed end block, use end block as the last reward block
                // so that for the next iteration, previous endBlock will be used as the last reward block
                if (block.number > _rewardInfo[_i].endBlock) {
                    campaign.lastRewardBlock = _rewardInfo[_i].endBlock;
                } else {
                    campaign.lastRewardBlock = block.number;
                }
                campaign.accRewardPerShare =
                    campaign.accRewardPerShare +
                    ((_multiplier * _rewardInfo[_i].rewardPerBlock * 1e20) / campaign.totalStaked);
            }
            unchecked {
                ++_i;
            }
        }
    }

    /**
     * @notice Withdraw staking token in a campaign. Also withdraw the current pending reward
     * @param _campaignID campaign id
     * @param _amount amount to withdraw
     */
    function _withdraw(uint256 _campaignID, uint256 _amount) internal {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        UserInfo storage user = userInfo[_campaignID][msg.sender];
        require(user.amount >= _amount, "FarmingRange::withdraw::bad withdraw amount");
        _updateCampaign(_campaignID);
        uint256 _pending = (user.amount * campaign.accRewardPerShare) / 1e20 - user.rewardDebt;
        if (_pending != 0) {
            campaign.rewardToken.safeTransfer(msg.sender, _pending);
        }
        if (_amount != 0) {
            user.amount = user.amount - _amount;
            campaign.totalStaked = campaign.totalStaked - _amount;
            campaign.stakingToken.safeTransfer(msg.sender, _amount);
        }
        user.rewardDebt = (user.amount * campaign.accRewardPerShare) / 1e20;

        emit Withdraw(msg.sender, _amount, _campaignID);
    }
}