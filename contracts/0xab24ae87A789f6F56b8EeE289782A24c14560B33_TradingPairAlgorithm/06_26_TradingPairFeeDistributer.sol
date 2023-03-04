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
    mapping(address => uint256) _feeTokenLocks;
    mapping(address => uint256) _claimRounds;
    uint256 _totalFeetokensLocked;
    // fee round
    uint256 _feeRoundNumber;
    uint256 immutable _feeRoundInterval;
    uint256 _nextFeeRoundTime;
    // assets
    ItemRef _asset1;
    ItemRef _asset2;
    // distribution snapshot
    uint256 _currentRoundBeginingTotalFeeTokensLocked;
    uint256 _asset1ToDistributeCurrentRound;
    uint256 _asset2ToDistributeCurrentRound;
    // statistics
    uint256 _asset1DistributedTotal;
    uint256 _asset2DistributedTotal;

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
        _feeRoundInterval = feeRoundIntervalHours_ * 1 hours;
        _nextFeeRoundTime = block.timestamp + _feeRoundInterval;

        // create assets for fee
        _asset1 = asset1_.clone(address(this));
        _asset2 = asset2_.clone(address(this));
    }

    function feeRoundNumber() external view returns (uint256) {
        if (this.nextFeeRoundLapsedTime() == 0) return _feeRoundNumber + 1;
        return _feeRoundNumber;
    }

    function feeRoundInterval() external view returns (uint256) {
        return _feeRoundInterval;
    }

    function getLock(address account) external view returns (uint256) {
        return _feeTokenLocks[account];
    }

    function getClaimRound(address account) external view returns (uint256) {
        return _claimRounds[account];
    }

    function lockFeeTokens(uint256 amount) external {
        _tryNextFeeRound();
        _claimRewards(msg.sender);
        feeToken.transferFrom(msg.sender, address(this), amount);
        _feeTokenLocks[msg.sender] += amount;
        _totalFeetokensLocked += amount;
        emit OnLock(msg.sender, amount);
    }

    function unlockFeeTokens(uint256 amount) external {
        _tryNextFeeRound();
        _claimRewards(msg.sender);
        require(_feeTokenLocks[msg.sender] >= amount, 'not enough fee tokens');
        feeToken.transfer(msg.sender, amount);
        _feeTokenLocks[msg.sender] -= amount;
        _totalFeetokensLocked -= amount;
        emit OnUnlock(msg.sender, amount);
    }

    function totalFeeTokensLocked() external view returns (uint256) {
        return _totalFeetokensLocked;
    }

    function currentRoundBeginingTotalFeeTokensLocked()
        external
        view
        returns (uint256)
    {
        return _currentRoundBeginingTotalFeeTokensLocked;
    }

    function asset1ToDistributeCurrentRound() external view returns (uint256) {
        uint256 expectedAsset1ToDistributeCurrentRound = _asset1ToDistributeCurrentRound;
        if (this.nextFeeRoundLapsedTime() == 0) {
            expectedAsset1ToDistributeCurrentRound = _asset1.count();
        }
        return expectedAsset1ToDistributeCurrentRound;
    }

    function asset2ToDistributeCurrentRound() external view returns (uint256) {
        uint256 expectedAsset2ToDistributeCurrentRound = _asset2ToDistributeCurrentRound;
        if (this.nextFeeRoundLapsedTime() == 0) {
            expectedAsset2ToDistributeCurrentRound = _asset2.count();
        }
        return expectedAsset2ToDistributeCurrentRound;
    }

    function assetsToDistributeCurrentRound()
        external
        view
        returns (uint256, uint256)
    {
        uint256 expectedAsset1ToDistributeCurrentRound = _asset1ToDistributeCurrentRound;
        uint256 expectedAsset2ToDistributeCurrentRound = _asset2ToDistributeCurrentRound;
        if (this.nextFeeRoundLapsedTime() == 0) {
            expectedAsset1ToDistributeCurrentRound = _asset1.count();
            expectedAsset2ToDistributeCurrentRound = _asset2.count();
        }

        return (
            expectedAsset1ToDistributeCurrentRound,
            expectedAsset2ToDistributeCurrentRound
        );
    }

    function asset1DistributedTotal() external view returns (uint256) {
        return _asset1DistributedTotal;
    }

    function asset2DistributedTotal() external view returns (uint256) {
        return _asset2DistributedTotal;
    }

    function assetsDistributedTotal() external view returns (uint256, uint256) {
        return (_asset1DistributedTotal, _asset2DistributedTotal);
    }

    function tryNextFeeRound() external {
        _tryNextFeeRound();
    }

    function _tryNextFeeRound() internal {
        //console.log('_nextFeeRoundTime-block.timestamp', _nextFeeRoundTime-block.timestamp);
        if (block.timestamp < _nextFeeRoundTime) return;
        ++_feeRoundNumber;
        _nextFeeRoundTime = block.timestamp + _feeRoundInterval;
        // snapshot for distribute
        _currentRoundBeginingTotalFeeTokensLocked = _totalFeetokensLocked;
        _asset1ToDistributeCurrentRound = _asset1.count();
        _asset2ToDistributeCurrentRound = _asset2.count();
    }

    function getExpectedRewardForAccount(address account)
        external
        view
        returns (uint256, uint256)
    {
        uint256 expectedRoundNumber = _feeRoundNumber;
        if (this.nextFeeRoundLapsedTime() == 0) ++expectedRoundNumber;
        if (_claimRounds[msg.sender] >= expectedRoundNumber) return (0, 0);
        return this.getExpectedRewardForTokensCount(_feeTokenLocks[account]);
    }

    function getExpectedRewardForAccountNextRound(address account)
        external
        view
        returns (uint256, uint256)
    {
        return
            this.getExpectedRewardForTokensCountNextRound(
                _feeTokenLocks[account]
            );
    }

    function claimRewards() external {
        _tryNextFeeRound();
        require(_feeRoundNumber > 0, 'nothing to claim');
        require(
            _claimRounds[msg.sender] < _feeRoundNumber,
            'claimed yet or stacked on current round - wait for next round'
        );
        require(_feeTokenLocks[msg.sender] > 0, 'has no lock');
        _claimRewards(msg.sender);
    }

    function _claimRewards(address account) internal {
        if (_claimRounds[account] >= _feeRoundNumber) return;
        _claimRounds[account] = _feeRoundNumber;
        uint256 feeTokensCount = _feeTokenLocks[account];

        (uint256 asset1Count, uint256 asset2Count) = _getRewardForTokensCount(
            feeTokensCount,
            _currentRoundBeginingTotalFeeTokensLocked,
            _asset1ToDistributeCurrentRound,
            _asset2ToDistributeCurrentRound
        );
        _asset1DistributedTotal += asset1Count;
        _asset2DistributedTotal += asset2Count;
        if (asset1Count > 0) _asset1.withdraw(account, asset1Count);
        if (asset2Count > 0) _asset2.withdraw(account, asset2Count);

        ITradingPairAlgorithm(this.tradingPair()).ClaimFeeReward(
            _positionId,
            account,
            asset1Count,
            asset2Count,
            feeTokensCount
        );

        emit OnClaim(account, asset1Count, asset2Count);
    }

    /// @dev reward for tokens count
    function getExpectedRewardForTokensCount(uint256 feeTokensCount)
        external
        view
        returns (uint256, uint256)
    {
        uint256 expectedRoundNumber = _feeRoundNumber;
        uint256 expectedCurrentRoundBeginingTotalFeeTokensLocked = _currentRoundBeginingTotalFeeTokensLocked;
        uint256 expectedAsset1ToDistributeCurrentRound = _asset1ToDistributeCurrentRound;
        uint256 expectedAsset2ToDistributeCurrentRound = _asset2ToDistributeCurrentRound;
        if (this.nextFeeRoundLapsedTime() == 0) {
            ++expectedRoundNumber;
            expectedCurrentRoundBeginingTotalFeeTokensLocked = _totalFeetokensLocked;
            expectedAsset1ToDistributeCurrentRound = _asset1.count();
            expectedAsset2ToDistributeCurrentRound = _asset2.count();
        }

        return
            _getRewardForTokensCount(
                feeTokensCount,
                expectedCurrentRoundBeginingTotalFeeTokensLocked,
                expectedAsset1ToDistributeCurrentRound,
                expectedAsset2ToDistributeCurrentRound
            );
    }

    function getExpectedRewardForTokensCountNextRound(uint256 feeTokensCount)
        external
        view
        returns (uint256, uint256)
    {
        return
            _getRewardForTokensCount(
                feeTokensCount,
                _totalFeetokensLocked,
                _asset1.count(),
                _asset2.count()
            );
    }

    function _getRewardForTokensCount(
        uint256 feeTokensCount,
        uint256 totalFeeTokensLockedAtRound,
        uint256 asset1ToDistributeAtRound,
        uint256 asset2ToDistributeAtRound
    ) internal pure returns (uint256, uint256) {
        return (
            totalFeeTokensLockedAtRound > 0
                ? (asset1ToDistributeAtRound * feeTokensCount) /
                    totalFeeTokensLockedAtRound
                : (feeTokensCount > 0 ? asset1ToDistributeAtRound : 0),
            totalFeeTokensLockedAtRound > 0
                ? (asset2ToDistributeAtRound * feeTokensCount) /
                    totalFeeTokensLockedAtRound
                : (feeTokensCount > 0 ? asset2ToDistributeAtRound : 0)
        );
    }

    function nextFeeRoundLapsedMinutes() external view returns (uint256) {
        return this.nextFeeRoundLapsedTime() / (1 minutes);
    }

    function nextFeeRoundLapsedTime() external view returns (uint256) {
        if (block.timestamp >= _nextFeeRoundTime) return 0;
        return _nextFeeRoundTime - block.timestamp;
    }

    function nextFeeRoundTime() external view returns (uint256) {
        return _nextFeeRoundTime;
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