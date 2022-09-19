// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../FarmV2Context.sol";

// solhint-disable not-rely-on-time
abstract contract FarmV2Depositable is FarmV2Context {
    /**
     * @dev Emit when the account deposit tokens to the pool.
     */
    event Deposited(address indexed account, uint256 indexed amount);

    /**
     * @dev Deposit the tokens to the pool and start earning.
     */
    function deposit(uint256 amount) external virtual nonReentrant {
        if (!isStarted()) {
            revert PoolIsNotStarted();
        }

        address account = _msgSender();

        if (amount <= 0 || amount > maxDeposit(account)) {
            revert InvalidAmount();
        }

        // Transfer tokens to this contract.
        uint256 balanceBefore = stakeTokenBalance();

        // slither-disable-next-line reentrancy-no-eth,reentrancy-benign
        if (!stakeToken().transferFrom(account, address(this), amount)) {
            revert TransferFailed();
        }

        uint256 balanceAfter = stakeTokenBalance();

        // Get the real deposited amount if the stake token has fee.
        unchecked {
            if (balanceAfter <= balanceBefore) {
                revert TransferFailed();
            }

            uint256 realAmount = balanceAfter - balanceBefore;

            if (realAmount < amount) {
                amount = realAmount;
            }
        }

        // Save deposit informations.
        _deposits[account].push(
            Deposit({
                amount: amount,
                claimed: 0,
                harvested: 0,
                time: block.timestamp,
                lastWithdrawAt: block.timestamp,
                isEnded: false
            })
        );

        unchecked {
            _balances[account] += amount;
            _totalStaked += amount;
        }

        emit Deposited(account, amount);
    }

    /**
     * @dev Calculator the maximum depositable amount.
     */
    function available() public view virtual returns (uint256 result) {
        uint256 pool = rewardsPool();

        if (pool <= 0) {
            return 0;
        }

        unchecked {
            // slither-disable-next-line divide-before-multiply
            result = (pool * 10**decimals()) / ((apr() / 100 / YEAR) * duration());

            // Round the result to ensure the earned tokens always
            // less than rewards pool.
            uint256 denominators = 10**rewardsToken().decimals();

            // slither-disable-next-line divide-before-multiply
            result = denominators * (result / denominators);

            // Div result for rewards rate.
            result = (result * 10**decimals()) / rewardsRate();
        }

        unchecked {
            uint256 totalStaked_ = totalStaked();

            if (result <= totalStaked_) {
                return 0;
            }

            result -= totalStaked_;
        }
    }

    /**
     * @dev Returns the maximum depositable amount of the account.
     */
    function maxDeposit(address account) public view virtual returns (uint256) {
        uint256 balance = stakeToken().balanceOf(account);
        uint256 depositablePerAccount = maxDepositPerAccount();
        uint256 depositable = Math.min(balance, available());

        if (depositablePerAccount > 0) {
            uint256 staked = balanceOf(account);

            if (staked >= depositablePerAccount) {
                return 0;
            }

            unchecked {
                depositablePerAccount -= staked;
            }

            return Math.min(depositablePerAccount, depositable);
        }

        return depositable;
    }
}