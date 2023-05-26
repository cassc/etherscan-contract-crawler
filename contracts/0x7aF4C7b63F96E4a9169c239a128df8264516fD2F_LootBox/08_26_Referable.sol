// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract Referable {

    struct BIPS {
        uint64 initial;
        uint64 max;
        uint64 step;
    }

    struct Referrer {
        uint128 balance;
        uint64 bips;
        uint64 referrals;
    }


    BIPS public _bips;

    mapping(address => Referrer) private _referrers;


    uint256 public _totalReferralBalance;


    function _referral(address account, uint256 quantity, uint256 value) internal {
        if (account == address(0)) {
            return;
        }

        Referrer storage referrer = _referrers[account];
        BIPS memory b = _bips;

        if (referrer.bips == 0) {
            referrer.bips = _bips.initial;
        }

        uint128 balance = (referrer.bips * uint128(value)) / 10000;

        referrer.balance += balance;
        referrer.referrals += uint64(quantity);
        _totalReferralBalance += uint256(balance);

        uint64 bips = b.initial + b.step * referrer.referrals;

        if (bips > b.max) {
            bips = b.max;
        }

        referrer.bips = bips;
    }

    function _setReferralBIPS(BIPS memory bips) internal {
        _bips = bips;
    }

    function _withdrawReferralBalance(address account) internal returns (uint256) {
        Referrer storage referrer = _referrers[account];
        uint128 balance = referrer.balance;

        referrer.balance = 0;
        _totalReferralBalance -= balance;

        return uint256(balance);
    }
}