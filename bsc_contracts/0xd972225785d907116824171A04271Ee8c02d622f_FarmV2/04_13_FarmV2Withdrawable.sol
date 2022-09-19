// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;

import "./FarmV2Earnable.sol";

// solhint-disable not-rely-on-time
abstract contract FarmV2Withdrawable is FarmV2Earnable {
    /**
     * @dev Emit when the account withdraw deposited tokens from the pool.
     */
    event Withdrawed(address indexed account, uint256 indexed amount);

    /**
     * @dev Withdraw the deposited tokens from the pool.
     */
    function withdraw(uint256 amount) external virtual nonReentrant {
        if (amount <= 0) {
            revert InvalidAmount();
        }

        address account = _msgSender();
        uint256 amount_ = amount;

        (Deposit[] memory deposits_, uint256 apr_, uint256 duration_, bool isLocked_) = (
            _deposits[account],
            apr(),
            duration(),
            isLocked()
        );

        unchecked {
            for (uint256 i = 0; i < deposits_.length; ++i) {
                Deposit memory deposit_ = deposits_[i];

                // If tokens is not unlocked, skip to next deposit.
                if (isLocked_ && block.timestamp < deposit_.time + duration_) {
                    continue;
                }

                if (deposit_.amount <= 0) {
                    continue;
                }

                // Update deposit informations.
                deposit_.claimed = _earned(deposit_, apr_, duration_);

                if (deposit_.claimed > 0) {
                    _totalClaimed += deposit_.claimed;
                }

                deposit_.harvested = 0;
                deposit_.lastWithdrawAt = block.timestamp;

                // Update the deposit ended status to ensure next withdraw
                // not recalculate earned on remaining amount.
                if (deposit_.lastWithdrawAt >= deposit_.time + duration_) {
                    deposit_.isEnded = true;
                }

                // Update amount.
                if (amount_ >= deposit_.amount) {
                    amount_ -= deposit_.amount;
                    deposit_.amount = 0;
                } else {
                    deposit_.amount -= amount_;
                    amount_ = 0;
                }

                _deposits[account][i] = deposit_;

                if (amount_ < deposit_.amount) {
                    break;
                }
            }
        }

        if (amount_ != 0) {
            revert InsufficientBalance();
        }

        unchecked {
            _balances[account] -= amount;
            _totalStaked -= amount;
            _totalWithdrawed += amount;
        }

        // Transfer tokens to the account.
        if (!stakeToken().transfer(account, amount)) {
            revert TransferFailed();
        }

        emit Withdrawed(account, amount);
    }

    /**
     * @dev Returns the maximum withdrawable tokens.
     */
    function withdrawable(address account) external view virtual returns (uint256 amount) {
        uint256 balance = balanceOf(account);

        if (!isLocked() || balance <= 0) {
            return balance;
        }

        (Deposit[] memory deposits_, uint256 duration_) = (_deposits[account], duration());

        for (uint256 i = 0; i < deposits_.length; ++i) {
            unchecked {
                if (block.timestamp < deposits_[i].time + duration_) {
                    continue;
                }

                amount += deposits_[i].amount;
            }
        }
    }
}