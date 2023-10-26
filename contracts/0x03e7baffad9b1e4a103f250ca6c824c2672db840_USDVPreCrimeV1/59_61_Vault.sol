// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library Vault {
    using SafeCast for uint192;

    struct ColorBook {
        uint64 shares;
        uint64 debt;
        uint64 rewards;
    }

    struct Info {
        uint192 accumRewardPerShare; //multiplied by RewardMultiplier
        uint64 totalShares;
        mapping(uint32 color => ColorBook book) colorBooks;
    }

    uint192 internal constant REWARD_MULTIPLIER = 1e18;
    uint64 internal constant INT64_MAX = uint64(type(int64).max); // because we use int64 as delta

    error Overflow();
    error InsufficientShares();

    event WithdrewPending(uint32 indexed color, uint64 pendingReward, uint64 newReward);
    event RemovedShares(uint32 indexed color, uint64 sharesDelta, uint64 newReward);
    event AddedShares(uint32 indexed color, uint64 sharesDelta, uint64 newReward);
    event AddedRewards(uint32 indexed color, uint64 amount);

    function netShareValue(Info storage _self, uint64 _shares) internal view returns (uint64) {
        uint192 nav = (_self.accumRewardPerShare * _shares) / REWARD_MULTIPLIER;
        return nav.toUint64();
    }

    function getPendingReward(Info storage _self, uint32 _color) internal view returns (uint64) {
        ColorBook memory book = _self.colorBooks[_color];
        uint64 nav = netShareValue(_self, book.shares);
        return nav - book.debt;
    }

    /// @dev add shares
    function addShares(Info storage _self, uint32 _color, uint64 _sharesDelta) internal {
        ColorBook memory book = _self.colorBooks[_color];

        uint64 beforeShares = book.shares;
        book.shares += _sharesDelta;
        _self.totalShares += _sharesDelta;
        if (_self.totalShares > INT64_MAX) revert Overflow();

        // settle if any pending
        uint64 newReward = settle(_self, book, beforeShares, book.shares);

        // persist the state
        _self.colorBooks[_color] = book;

        emit AddedShares(_color, _sharesDelta, newReward);
    }

    /// @dev remove shares
    function removeShares(Info storage _self, uint32 _color, uint64 _sharesDelta) internal {
        ColorBook memory book = _self.colorBooks[_color];

        uint64 beforeShares = book.shares;
        if (_sharesDelta > book.shares) revert InsufficientShares();

        book.shares -= _sharesDelta;
        _self.totalShares -= _sharesDelta;

        // settle if any pending
        uint64 newReward = settle(_self, book, beforeShares, book.shares);

        // persist the state
        _self.colorBooks[_color] = book;

        emit RemovedShares(_color, _sharesDelta, newReward);
    }

    /// @dev there may be rounding error that the usdv vault balance is not enough to pay the reward
    function withdrawPending(Info storage _self, uint32 _color, uint64 _cap) internal returns (uint64 pendingReward) {
        ColorBook memory book = _self.colorBooks[_color];
        // settle if any pending
        uint64 newReward = settle(_self, book, book.shares, book.shares);

        // check if the reward is enough to pay
        pendingReward = _cap >= book.rewards ? book.rewards : _cap;
        book.rewards -= pendingReward;

        // persist the state
        _self.colorBooks[_color] = book;

        emit WithdrewPending(_color, pendingReward, newReward);
    }

    /// @dev store the pending reward
    /// @dev steam payment is gas costly and it has some failure surfaces.
    function settle(
        Info storage _self,
        ColorBook memory _book,
        uint64 _beforeShares,
        uint64 _afterShares
    ) private view returns (uint64 newReward) {
        // harvest the outstanding into stored
        newReward = netShareValue(_self, _beforeShares) - _book.debt;
        _book.rewards += newReward;
        // update the debt
        _book.debt = netShareValue(_self, _afterShares);
    }

    function addReward(Info storage _self, uint _rewardInUSDV) internal {
        // we need to calculate the accumulative reward in shares to compound the yields
        _self.accumRewardPerShare += (uint192(_rewardInUSDV) * REWARD_MULTIPLIER) / _self.totalShares;
    }

    // function to add to store
    function addRewardByColor(Info storage _self, uint32 _color, uint64 _amount) internal {
        _self.colorBooks[_color].rewards += _amount;
        emit AddedRewards(_color, _amount);
    }
}