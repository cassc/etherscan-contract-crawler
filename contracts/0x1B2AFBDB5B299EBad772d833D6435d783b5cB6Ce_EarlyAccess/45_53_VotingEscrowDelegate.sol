// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./interfaces/IVotingEscrowDelegate.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/INFT.sol";

abstract contract VotingEscrowDelegate is IVotingEscrowDelegate {
    address public immutable ve;
    address public immutable token;
    address public immutable discountToken;

    uint256 internal immutable _maxDuration;
    uint256 internal immutable _interval;

    event CreateLock(address indexed account, uint256 amount, uint256 discount, uint256 indexed locktime);
    event IncreaseAmount(address indexed account, uint256 amount, uint256 discount);

    constructor(
        address _ve,
        address _token,
        address _discountToken
    ) {
        ve = _ve;
        token = _token;
        discountToken = _discountToken;

        _maxDuration = IVotingEscrow(_ve).maxDuration();
        _interval = IVotingEscrow(ve).interval();
    }

    modifier eligibleForDiscount {
        require(INFT(discountToken).balanceOf(msg.sender) > 0, "VED: DISCOUNT_TOKEN_NOT_OWNED");
        _;
    }

    function createLockDiscounted(uint256 amount, uint256 duration) external eligibleForDiscount {
        _createLock(amount, duration, true);
    }

    function createLock(uint256 amount, uint256 duration) external {
        _createLock(amount, duration, false);
    }

    function _createLock(
        uint256 amount,
        uint256 duration,
        bool discounted
    ) internal virtual {
        require(duration <= _maxDuration, "VED: DURATION_TOO_LONG");

        uint256 unlockTime = ((block.timestamp + duration) / _interval) * _interval; // rounded down to a multiple of interval
        uint256 _duration = unlockTime - block.timestamp;
        (uint256 amountVE, uint256 amountToken) = _getAmounts(amount, _duration);
        if (discounted) {
            amountVE = (amountVE * 100) / 90;
        }

        emit CreateLock(msg.sender, amountVE, amountVE - amountToken, unlockTime);
        IVotingEscrow(ve).createLockFor(msg.sender, amountVE, amountVE - amountToken, _duration);
    }

    function increaseAmountDiscounted(uint256 amount) external eligibleForDiscount {
        _increaseAmount(amount, true);
    }

    function increaseAmount(uint256 amount) external {
        _increaseAmount(amount, false);
    }

    function _increaseAmount(uint256 amount, bool discounted) internal virtual {
        uint256 unlockTime = IVotingEscrow(ve).unlockTime(msg.sender);
        require(unlockTime > 0, "VED: LOCK_NOT_FOUND");

        (uint256 amountVE, uint256 amountToken) = _getAmounts(amount, unlockTime - block.timestamp);
        if (discounted) {
            amountVE = (amountVE * 100) / 90;
        }

        emit IncreaseAmount(msg.sender, amountVE, amountVE - amountToken);
        IVotingEscrow(ve).increaseAmountFor(msg.sender, amountVE, amountVE - amountToken);
    }

    function _getAmounts(uint256 amount, uint256 duration)
        internal
        view
        virtual
        returns (uint256 amountVE, uint256 amountToken);

    function withdraw(address, uint256) external virtual override {
        // Empty
    }
}