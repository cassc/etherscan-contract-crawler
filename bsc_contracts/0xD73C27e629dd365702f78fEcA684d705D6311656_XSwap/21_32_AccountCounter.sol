// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library AccountCounter {
    uint256 private constant _ACCOUNT_MIXIN = 0xacc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0acc0;
    uint256 private constant _NULL_INDEX = type(uint256).max;

    struct State {
        uint256[] _accounts;
        uint256[] _counts;
        uint256 _size;
    }

    using AccountCounter for State;

    function create(uint256 maxSize_) internal pure returns (AccountCounter.State memory accountCounter) {
        accountCounter._accounts = new uint256[](maxSize_);
        accountCounter._counts = new uint256[](maxSize_);
    }

    function size(AccountCounter.State memory accountCounter_) internal pure returns (uint256) {
        return accountCounter_._size;
    }

    function indexOf(AccountCounter.State memory accountCounter_, address account_, bool insert_) internal pure returns (uint256) {
        uint256 targetAccount = uint160(account_) ^ _ACCOUNT_MIXIN;
        for (uint256 i = 0; i < accountCounter_._accounts.length; i++) {
            uint256 iAccount = accountCounter_._accounts[i];
            if (iAccount == targetAccount) return i;
            if (iAccount == 0) {
                if (!insert_) return _NULL_INDEX;
                accountCounter_._accounts[i] = targetAccount;
                accountCounter_._size = i + 1;
                return i;
            }
        }
        if (!insert_) return _NULL_INDEX;
        revert("AC: insufficient size");
    }

    function indexOf(AccountCounter.State memory accountCounter_, address account_) internal pure returns (uint256) {
        return indexOf(accountCounter_, account_, true);
    }

    function isNullIndex(uint256 index_) internal pure returns (bool) {
        return index_ == _NULL_INDEX;
    }

    function accountAt(AccountCounter.State memory accountCounter_, uint256 index_) internal pure returns (address) {
        return address(uint160(accountCounter_._accounts[index_] ^ _ACCOUNT_MIXIN));
    }

    function get(AccountCounter.State memory accountCounter_, address account_) internal pure returns (uint256) {
        return getAt(accountCounter_, indexOf(accountCounter_, account_));
    }

    function getAt(AccountCounter.State memory accountCounter_, uint256 index_) internal pure returns (uint256) {
        return accountCounter_._counts[index_];
    }

    function set(AccountCounter.State memory accountCounter_, address account_, uint256 count_) internal pure {
        setAt(accountCounter_, indexOf(accountCounter_, account_), count_);
    }

    function setAt(AccountCounter.State memory accountCounter_, uint256 index_, uint256 count_) internal pure {
        accountCounter_._counts[index_] = count_;
    }

    function add(AccountCounter.State memory accountCounter_, address account_, uint256 count_) internal pure returns (uint256 newCount) {
        return addAt(accountCounter_, indexOf(accountCounter_, account_), count_);
    }

    function addAt(AccountCounter.State memory accountCounter_, uint256 index_, uint256 count_) internal pure returns (uint256 newCount) {
        newCount = getAt(accountCounter_, index_) + count_;
        setAt(accountCounter_, index_, newCount);
    }

    function sub(AccountCounter.State memory accountCounter_, address account_, uint256 count_) internal pure returns (uint256 newCount) {
        return subAt(accountCounter_, indexOf(accountCounter_, account_), count_);
    }

    function subAt(AccountCounter.State memory accountCounter_, uint256 index_, uint256 count_) internal pure returns (uint256 newCount) {
        newCount = getAt(accountCounter_, index_) - count_;
        setAt(accountCounter_, index_, newCount);
    }
}