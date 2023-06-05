// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

error AlreadyWithdrawnForThisMonth();
error AmountExceedsBalance(string method);
error TransferFailed();
error WithdrawLockupActive();

abstract contract Withdrawable {

    bool private _locked;

    mapping(uint256 => bool) private _months;


    function _withdraw(address receiver, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AmountExceedsBalance({ method: '_withdraw' });
        }

        (bool success, ) = payable(receiver).call{value: amount}("");

        if (!success) {
            revert TransferFailed();
        }
    }

    // Withdraw x% once per month
    function _withdrawOncePerMonth(address receiver, uint256 bips, uint256 deployedAt) internal {
        unchecked {
            uint256 amount = address(this).balance;
            uint256 month = ((block.timestamp - deployedAt) / 4 weeks) + 1;

            if (_months[month]) {
                revert AlreadyWithdrawnForThisMonth();
            }

            _months[month] = true;

            _withdraw(receiver, (amount * bips) / 10000);
        }
    }

    // Withdraw With x% Lockup
    // - x% available for withdraw on sale
    // - x% held by contract until `timestamp`
    function _withdrawWithLockup(address receiver, uint256 bips, uint256 unlockAt) internal {
        unchecked {
            uint256 amount = address(this).balance;

            if (amount < ((amount * bips) / 10000)) {
                revert AmountExceedsBalance({ method: '_withdrawWithLockup' });
            }

            // x% can be withdrawn to kickstart project; Remaining x% will be
            // held throughout `lockup` period
            if (!_locked) {
                amount = (amount * bips) / 10000;
                _locked = true;
            }
            else if (block.timestamp < unlockAt) {
                revert WithdrawLockupActive();
            }

            _withdraw(receiver, amount);
        }
    }
}