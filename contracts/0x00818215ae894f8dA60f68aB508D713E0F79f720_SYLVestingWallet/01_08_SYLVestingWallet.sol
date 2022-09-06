// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @author syllabs
 * @title SYLVestingWallet
 * @dev Modified OpenZeppelin 4.4.1 {VestingWallet} to enable transferring beneficiary.
 */
contract SYLVestingWallet is Ownable {
    event SYLReleased(uint256 amount);

    IERC20 private immutable _erc20;
    uint256 private _erc20Released;
    address private _beneficiary;
    uint64 private immutable _start;
    uint64 private immutable _duration;

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(
        address erc20Address,
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) {
        require(beneficiaryAddress != address(0), "Beneficiary cannot be address zero");
        _erc20 = IERC20(erc20Address);
        _beneficiary = beneficiaryAddress;
        _start = startTimestamp;
        _duration = durationSeconds;
    }

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Setter for the beneficiary address.
     */
    function setBeneficiary(address beneficiaryAddress) external onlyOwner {
        require(beneficiaryAddress != address(0), "Beneficiary cannot be address zero");
        _beneficiary = beneficiaryAddress;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return _start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Amount of token already released
     */
    function released() public view virtual returns (uint256) {
        return _erc20Released;
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {TokensReleased} event.
     */
    function release() public virtual {
        uint256 releasable = vestedAmount(uint64(block.timestamp)) - released();
        _erc20Released += releasable;
        emit SYLReleased(releasable);
        SafeERC20.safeTransfer(_erc20, beneficiary(), releasable);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(_erc20.balanceOf(address(this)) + released(), timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view virtual returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }
}