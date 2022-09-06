// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./VotingEscrowDelegate.sol";

contract BoostedVotingEscrowDelegate is VotingEscrowDelegate {
    uint256 public immutable minDuration;
    uint256 public immutable maxBoost;
    uint256 public immutable deadline;

    constructor(
        address _ve,
        address _token,
        address _discountToken,
        uint256 _minDuration,
        uint256 _maxBoost,
        uint256 _deadline
    ) VotingEscrowDelegate(_ve, _token, _discountToken) {
        minDuration = _minDuration;
        maxBoost = _maxBoost;
        deadline = _deadline;
    }

    function _createLock(
        uint256 amountToken,
        uint256 duration,
        bool discounted
    ) internal override {
        require(block.timestamp < deadline, "BVED: EXPIRED");
        require(duration >= minDuration, "BVED: DURATION_TOO_SHORT");

        super._createLock(amountToken, duration, discounted);
    }

    function _increaseAmount(uint256 amountToken, bool discounted) internal override {
        require(block.timestamp < deadline, "BVED: EXPIRED");

        super._increaseAmount(amountToken, discounted);
    }

    function _getAmounts(uint256 amount, uint256 duration)
        internal
        view
        override
        returns (uint256 amountVE, uint256 amountToken)
    {
        amountVE = (amount * maxBoost * duration) / _maxDuration;
        amountToken = amount;
    }
}