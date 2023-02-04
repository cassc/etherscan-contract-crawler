// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/lib/ownable/OwnableSimple.sol';
import 'contracts/position_trading/ItemRefAsAssetLibrary.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import 'contracts/position_trading/algorithms/TradingPair/ITradingPairAlgorithm.sol';
import 'contracts/position_trading/algorithms/TradingPair/ITradingPairFeeDistributer.sol';
import 'contracts/position_trading/AssetTransferData.sol';

contract TradingPairFeeDistributer is
    OwnableSimple,
    ITradingPairFeeDistributer
{
    using ItemRefAsAssetLibrary for ItemRef;

    uint256 immutable _positionId;

    // fee token
    IERC20 public immutable feeToken;
    // fee token user locks
    mapping(address => uint256) public feeTokenLocks;
    mapping(address => uint256) public claimRounds;
    uint256 public totalFeetokensLocked;
    // fee round
    uint256 public feeRoundNumber;
    uint256 public immutable feeRoundInterval;
    uint256 public nextFeeRoundTime;
    // assets
    ItemRef _asset1;
    ItemRef _asset2;
    // distribution snapshot
    uint256 public distributeRoundTotalFeeTokensLock;
    uint256 public ownerAssetToDistribute;
    uint256 public outputAssetToDistribute;
    // statistics
    uint256 public ownerAssetDistributedTotal;
    uint256 public outputAssetDistributedTotal;
    // events
    event OnLock(address indexed account, uint256 amount);
    event OnUnlock(address indexed account, uint256 amount);

    constructor(
        uint256 positionId_,
        address tradingPair_,
        address feeTokenAddress_,
        ItemRef memory asset1_,
        ItemRef memory asset2_,
        uint256 feeRoundIntervalHours_
    ) OwnableSimple(tradingPair_) {
        _positionId = positionId_;
        feeToken = IERC20(feeTokenAddress_);
        feeRoundInterval = feeRoundIntervalHours_ * 1 hours;
        nextFeeRoundTime = block.timestamp + feeRoundInterval;

        // create assets for fee
        _asset1 = asset1_.clone(
            address(this)
        );
        _asset2 = asset2_.clone(
            address(this)
        );
    }

    function lockFeeTokens(uint256 amount) external {
        _claimRewards(msg.sender);
        _tryNextFeeRound();
        feeToken.transferFrom(msg.sender, address(this), amount);
        feeTokenLocks[msg.sender] += amount;
        totalFeetokensLocked += amount;
        emit OnLock(msg.sender, amount);
    }

    function unlockFeeTokens(uint256 amount) external {
        _claimRewards(msg.sender);
        _tryNextFeeRound();
        require(feeTokenLocks[msg.sender] >= amount, 'not enough fee tkns');
        feeTokenLocks[msg.sender] -= amount;
        totalFeetokensLocked -= amount;
        emit OnUnlock(msg.sender, amount);
    }

    function tryNextFeeRound() external {
        _tryNextFeeRound();
    }

    function _tryNextFeeRound() internal {
        //console.log('nextFeeRoundTime-block.timestamp', nextFeeRoundTime-block.timestamp);
        if (block.timestamp < nextFeeRoundTime) return;
        ++feeRoundNumber;
        nextFeeRoundTime = block.timestamp + feeRoundInterval;
        // snapshot for distribute
        distributeRoundTotalFeeTokensLock = totalFeetokensLocked;
        ownerAssetToDistribute = _asset1.count();
        outputAssetToDistribute = _asset2.count();
    }

    function claimRewards() external {
        _tryNextFeeRound();
        require(feeRoundNumber > 0, 'nthing claim');
        require(claimRounds[msg.sender] < feeRoundNumber, 'climd yet');
        require(feeTokenLocks[msg.sender] > 0, 'has no lck');
        _claimRewards(msg.sender);
    }

    function _claimRewards(address account) internal {
        if (claimRounds[account] >= feeRoundNumber) return;
        claimRounds[account] = feeRoundNumber;
        uint256 feeTokensCount = feeTokenLocks[account];

        (uint256 asset1Count, uint256 asset2Count) = this
            .getRewardForTokensCount(feeTokensCount);
        ownerAssetDistributedTotal += asset1Count;
        outputAssetDistributedTotal += asset2Count;
        if (asset1Count > 0) _asset1.withdraw(account, asset1Count);
        if (asset2Count > 0) _asset2.withdraw(account, asset2Count);

        ITradingPairAlgorithm(this.tradingPair()).ClaimFeeReward(
            _positionId,
            account,
            asset1Count,
            asset2Count,
            feeTokensCount
        );
    }

    /// @dev reward for tokens count
    function getRewardForTokensCount(uint256 feeTokensCount)
        external
        view
        returns (uint256, uint256)
    {
        return (
            distributeRoundTotalFeeTokensLock > 0
                ? (ownerAssetToDistribute * feeTokensCount) /
                    distributeRoundTotalFeeTokensLock
                : 0,
            distributeRoundTotalFeeTokensLock > 0
                ? (outputAssetToDistribute * feeTokensCount) /
                    distributeRoundTotalFeeTokensLock
                : 0
        );
    }

    function nextFeeRoundLapsedMinutes() external view returns (uint256) {
        if (block.timestamp >= nextFeeRoundTime) return 0;
        return (nextFeeRoundTime - block.timestamp) / (1 minutes);
    }

    function asset(uint256 assetCode) external view returns (ItemRef memory) {
        if (assetCode == 1) return _asset1;
        else if (assetCode == 2) return _asset2;
        else revert('bad asset code');
    }

    function assetCount(uint256 assetCode) external view returns (uint256) {
        if (assetCode == 1) return _asset1.count();
        else if (assetCode == 2) return _asset2.count();
        else revert('bad asset code');
    }

    function allAssetsCounts()
        external
        view
        returns (uint256 asset1Count, uint256 asset2Count)
    {
        asset1Count = _asset1.count();
        asset2Count = _asset2.count();
    }

    function tradingPair() external view returns (address) {
        return _owner;
    }

    function positionId() external view returns (uint256) {
        return _positionId;
    }
}