// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./MetaOwnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an minter) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyMinter`, which can be applied to your functions to restrict their use to
 * the minter.
 */
abstract contract Mintable is MetaOwnable {
    using Counters for Counters.Counter;

    Counters.Counter internal _mintsCounter;

    // Max mints allowed in a day
    uint private _maxDailyMints;

    // To cap mints in a day
    uint private _lastChecked;

    // Whether minter can mint the rewards
    bool private _paused;

    // Account responsible for minting
    address private _minter;

    event MinterAccountChanged(
        address indexed previousMinter,
        address indexed newMinter
    );

    event DailyMintLimitChanged(
        uint indexed previousDailyMint,
        uint indexed newDailyMint
    );

    constructor(uint dailyLimit) {
        resetMintCount();
        setDailyMintLimit(dailyLimit);
    }

    /**
     * @dev set status of minting allowed or not
     *
     */
    function pauseMint() public onlyOwner {
        _paused = true;
    }

    /**
     * @dev set status of minting allowed or not
     *
     */
    function unPauseMint() public onlyOwner {
        _paused = false;
    }

    /**
     * @dev Returns whether minting is paused or not.
     *
     * @return status bool
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if minting is paused.
     */
    modifier mintingAllowed() {
        _checkMintingPaused();
        _;
    }

    /**
     * @dev Throws error if daily mints limit is reached
     */
    modifier inLimit() {
        _checkDailyLimit();
        _;
    }

    /**
     * @dev Throws error if daily mints limit is reached
     */
    function _checkDailyLimit() internal virtual returns (bool) {
        if (_mintsCounter.current() >= maxDailyMints()) {
            if (_checkDayPassed()) _resetMintCount();
            else {
                require(false, "Mintable: Daily Limit Reached");
            }
        }
        return true;
    }

    /**
     * @dev Checks whether it's been 24 hours since last checked
     */
    function _checkDayPassed() internal view virtual returns (bool) {
        if (block.timestamp >= (lastChecked() + 86400)) return true;
        return false;
    }

    /**
     * @dev Throws error if minting is paused.
     */
    function _checkMintingPaused() internal view virtual {
        require(paused() == false, "Mintable: Minting is paused for minter");
    }

    /**
     * @dev Throws if called by any account other than the minter.
     */
    modifier onlyMinter() {
        _checkMinter();
        _;
    }

    /**
     * @dev Returns the address of the current minter.
     */
    function minter() public view virtual returns (address) {
        return _minter;
    }

    /**
     * @dev Returns the number of mints since last timestamp checked.
     */
    function maxDailyMints() public view virtual returns (uint) {
        return _maxDailyMints;
    }

    /**
     * @dev Returns the number of mints since last timestamp check
     */
    function mintsCounter() public view virtual returns (uint) {
        return _mintsCounter.current();
    }

    /**
     * @dev Returns the timestamp of the last reset.
     */
    function lastChecked() public view virtual returns (uint) {
        return _lastChecked;
    }

    /**
     * @dev Throws if the sender is not the minter.
     */
    function _checkMinter() internal view virtual {
        require(minter() == _msgSender(), "Mintable: caller is not minter");
    }

    /**
     * @dev Transfers minter rights of the contract to a new account (`newMinter`).
     * Can only be called by the owner.
     */
    function setMinter(address newMinter) public onlyOwner {
        address oldMinter = _minter;
        _minter = newMinter;
        emit MinterAccountChanged(oldMinter, newMinter);
    }

    /**
     * @dev Updates daily mints count to a new number.
     * Can only be called by the owner.
     */
    function setDailyMintLimit(uint newDailyMint) public onlyOwner {
        require(newDailyMint > 0, "Mint limit must be greater than zero");
        uint oldDailyMint = _maxDailyMints;
        _maxDailyMints = newDailyMint;
        emit DailyMintLimitChanged(oldDailyMint, newDailyMint);
    }

    /**
     * @dev Resets mintsCounter and sets last checked timestamp to current
     *
     * Keeping this internal so that the inLimit modifier can call this
     *
     * Can only be called by an internal function.
     */
    function _resetMintCount() internal {
        _mintsCounter.reset();
        _lastChecked = block.timestamp;
    }

    /**
     * @dev Resets mintsCounter and sets last checked timestamp to current
     *
     * Can only be called by the owner.
     */
    function resetMintCount() public onlyOwner {
        _resetMintCount();
    }

    function _incrementMintCounter() internal {
        _mintsCounter.increment();
    }
}