// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

contract LeisureMeta is ERC20Burnable, Ownable, Pausable {
    uint256 private _dDay;

    mapping(address => LockedItem[]) private _lockedItems;

    mapping(address => LockedItem[]) private _revocablyLockedItems;

    struct LockedItem {
        uint256 amount;
        uint256 releaseTime;
    }

    event SetDDay(uint256 dDay);
    event DaoLock(address indexed beneficiary, uint256 totalAmount);
    event SalesLock(address indexed beneficiary, uint256 totalAmount);
    event GeneralLock(address indexed beneficiary, uint256 totalAmount);
    event CustomLock(
        address indexed beneficiary,
        uint256 totalAmount,
        uint256 partition,
        uint256 startMonth
    );
    event Revoke(address indexed from, uint256 amount, uint256 revokeTime);

    constructor(uint256 initialDDay)
        ERC20("LeisureMeta", "LM")
    {
        uint256 totalAmount = 5_000_000_000 * (10**uint256(decimals()));

        _dDay = initialDDay;

        _mint(_msgSender(), totalAmount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     * - the sender have enough unlocked tokens to transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            balanceOf(from) >= lockedAmount(from) + amount,
            "LM: insufficient balance"
        );

        clearUnnessaryLockedItems(from);
        super._transfer(from, to, amount);
    }

    /**
     * @dev Set D-Day which might be the first day of listing in major crypto exchanges.
     */
    function setDDay(uint256 dDay) external onlyOwner {
        _dDay = dDay;
        emit SetDDay(_dDay);
    }

    function getDDay() external view returns (uint256) {
        return _dDay;
    }

    function lockedItems(address beneficiary)
        external
        view
        returns (LockedItem[] memory)
    {
        return _lockedItems[beneficiary];
    }

    function revocablyLockedItems(address beneficiary)
        external
        view
        returns (LockedItem[] memory)
    {
        return _revocablyLockedItems[beneficiary];
    }

    function lockedAmount(address beneficiary) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _lockedItems[beneficiary].length; i++) {
            LockedItem storage item = _lockedItems[beneficiary][i];
            if (_dDay + item.releaseTime > block.timestamp)
                total += item.amount;
        }
        for (
            uint256 i = 0;
            i < _revocablyLockedItems[beneficiary].length;
            i++
        ) {
            LockedItem storage item = _revocablyLockedItems[beneficiary][i];
            if (_dDay + item.releaseTime > block.timestamp)
                total += item.amount;
        }
        return total;
    }

    function clearUnnessaryLockedItems(address from) internal {
        while (
            lockedItemSize(from) > 0 &&
            _dDay + _lockedItems[from][lockedItemSize(from) - 1].releaseTime <
            block.timestamp
        ) {
            _lockedItems[from].pop();
        }
        while (
            revocablyLockedItemSize(from) > 0 &&
            _dDay +
                _revocablyLockedItems[from][revocablyLockedItemSize(from) - 1]
                    .releaseTime <
            block.timestamp
        ) {
            _revocablyLockedItems[from].pop();
        }

        if (lockedItemSize(from) == 0) delete _lockedItems[from];
        if (revocablyLockedItemSize(from) == 0)
            delete _revocablyLockedItems[from];
    }

    function lockedItemSize(address beneficiary)
        internal
        view
        returns (uint256)
    {
        return _lockedItems[beneficiary].length;
    }

    function revocablyLockedItemSize(address beneficiary)
        internal
        view
        returns (uint256)
    {
        return _revocablyLockedItems[beneficiary].length;
    }

    function daoLock(address beneficiary, uint256 amount)
        external
        onlyOwner
    {
        uint256 aDay = 24 * 3600;
        for (uint256 i = 0; i < 60; i++) {
            _lockedItems[beneficiary].push(
                LockedItem({
                    amount: amount / 60,
                    releaseTime: 30 * aDay * (60 - i)
                })
            );
        }
        emit DaoLock(beneficiary, amount);
        address owner = _msgSender();
        super._transfer(owner, beneficiary, amount);
    }

    function saleLock(address beneficiary, uint256 amount)
        external
        onlyOwner
    {
        uint256 aDay = 24 * 3600;
        for (uint256 i = 0; i < 7; i++) {
            _lockedItems[beneficiary].push(
                LockedItem({
                    amount: amount / 7,
                    releaseTime: 30 * aDay * (10 - i)
                })
            );
        }
        emit SalesLock(beneficiary, amount);
        address owner = _msgSender();
        super._transfer(owner, beneficiary, amount);
    }

    function generalLock(address beneficiary, uint256 amount)
        external
        onlyOwner
    {
        uint256 aDay = 24 * 3600;
        for (uint256 i = 0; i < 20; i++) {
            _revocablyLockedItems[beneficiary].push(
                LockedItem({
                    amount: amount / 20,
                    releaseTime: 30 * aDay * (25 - i)
                })
            );
        }
        emit GeneralLock(beneficiary, amount);
        transfer(beneficiary, amount);
    }
    
    function customLock(address beneficiary, uint256 amount, uint256 partition, uint256 startMonth)
        external
        onlyOwner
    {
        uint256 aDay = 24 * 3600;
        for (uint256 i = 0; i < partition; i++) {
            _revocablyLockedItems[beneficiary].push(
                LockedItem({
                    amount: amount / partition,
                    releaseTime: 30 * aDay * ((partition + startMonth) - i)
                })
            );
        }
        emit CustomLock(beneficiary, amount, partition, startMonth);
        transfer(beneficiary, amount);
    }


    function revoke(address from) external onlyOwner {
        uint256 lockedTotal = 0;
        LockedItem[] storage items = _revocablyLockedItems[from];
        while (items.length > 0) {
            if (_dDay + items[items.length - 1].releaseTime > block.timestamp) {
                lockedTotal += items[items.length - 1].amount;
            }
            items.pop();
        }
        delete _revocablyLockedItems[from];
        emit Revoke(from, lockedTotal, block.timestamp);
        _approve(from, _msgSender(), lockedTotal);
        transferFrom(from, _msgSender(), lockedTotal);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}