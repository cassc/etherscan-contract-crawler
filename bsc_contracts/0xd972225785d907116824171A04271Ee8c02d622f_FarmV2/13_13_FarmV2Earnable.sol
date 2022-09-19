// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;

import "../FarmV2Context.sol";

// solhint-disable not-rely-on-time
abstract contract FarmV2Earnable is FarmV2Context {
    /**
     * @dev Emit when the account harvested successfully.
     */
    event Harvested(address indexed account, uint256 indexed amount);

    /**
     * @dev Harvest all earned tokens of the sender.
     */
    function harvest() external virtual nonReentrant {
        address account = _msgSender();
        uint256 earned_;

        (Deposit[] memory deposits_, uint256 apr_, uint256 duration_) = (_deposits[account], apr(), duration());

        unchecked {
            for (uint256 i = 0; i < deposits_.length; ++i) {
                uint256 earnedByDeposit = _earned(deposits_[i], apr_, duration_);

                if (earnedByDeposit > 0) {
                    _deposits[account][i].harvested += earnedByDeposit - deposits_[i].claimed;
                    _deposits[account][i].claimed = 0;
                }

                earned_ += earnedByDeposit;
            }

            earned_ /= 10**decimals();
        }

        if (earned_ <= 0) {
            revert InsufficientBalance();
        }

        if (!rewardsToken().transfer(account, earned_)) {
            revert TransferFailed();
        }

        unchecked {
            _totalHarvested += earned_;
        }

        emit Harvested(account, earned_);
    }

    /**
     * @dev Returns the total earned tokens of the account.
     */
    function earned(address account) external view virtual returns (uint256 earned_) {
        (Deposit[] memory deposits_, uint256 apr_, uint256 duration_) = (_deposits[account], apr(), duration());

        for (uint256 i = 0; i < deposits_.length; ++i) {
            unchecked {
                earned_ += _earned(deposits_[i], apr_, duration_);
            }
        }
    }

    /**
     * @dev Calculator the earned tokens of the deposit by specified APR
     * and duration.
     *
     * Calculation formula:
     *  + Rewards Per Seconds (RPS): amount * (APR / 365 days)%
     *  + Stake Time: now - stake start time
     *  + Earned: (RPS * min(Stake Time, duration) + claimed) - harvested
     */
    function _earned(
        Deposit memory deposit_,
        uint256 apr_,
        uint256 duration_
    ) internal view virtual returns (uint256 earned_) {
        uint256 amount = deposit_.amount;

        if (amount <= 0 || deposit_.isEnded) {
            return deposit_.claimed;
        }

        // Calculator the stake time.
        uint256 stakeTime = duration_;

        unchecked {
            uint256 end = deposit_.time + duration_;

            if (deposit_.lastWithdrawAt < end) {
                if (block.timestamp < end) {
                    end = block.timestamp;
                }

                stakeTime = end - deposit_.lastWithdrawAt;
            }
        }

        // Calculator the deposit amount by rewards rate.
        unchecked {
            amount = (amount * rewardsRate()) / 10**decimals();

            if (amount <= 0) {
                return deposit_.claimed;
            }
        }

        // Calculator earned tokens.
        unchecked {
            earned_ = ((amount * stakeTime * apr_) / YEAR / 100) + deposit_.claimed;

            if (earned_ <= deposit_.harvested) {
                return 0;
            }

            earned_ -= deposit_.harvested;
        }
    }
}