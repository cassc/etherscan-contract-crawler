// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

function _getVestedTkns(
    uint256 tknBalance_,
    uint256 tknWithdrawn_,
    uint256 startDate_,
    uint256 duration_
) view returns (uint256) {
    if (block.timestamp < startDate_) return 0;
    if (block.timestamp >= startDate_ + duration_)
        return tknBalance_ + tknWithdrawn_;
    return
        ((tknBalance_ + tknWithdrawn_) * (block.timestamp - startDate_)) /
        duration_;
}

function _getTknMaxWithdraw(
    uint256 tknBalance_,
    uint256 tknWithdrawn_,
    uint256 startDate_,
    uint256 cliffDuration_,
    uint256 duration_
) view returns (uint256) {
    // Vesting has not started and/or cliff has not passed
    if (block.timestamp < startDate_ + cliffDuration_) return 0;

    uint256 vestedTkns = _getVestedTkns(
        tknBalance_,
        tknWithdrawn_,
        startDate_,
        duration_
    );

    return vestedTkns > tknWithdrawn_ ? vestedTkns - tknWithdrawn_ : 0;
}