// SPDX-License-Identifier: UNLICENSED
/** 
 *   Copyright © 2022 Scratch Engine LLC. All rights reserved.
 *   Limited license is afforded to Etherscan, in accordance with its Terms of Use, 
 *   in order to publish this material.
 *   In connection with the foregoing, redistribution and use on the part of Etherscan,
 *   in source and binary forms, without modification, are permitted, 
 *   provided that such redistributions of source code retain the foregoing copyright notice
 *   and this disclaimer.
 */

pragma solidity 0.8.4;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title FoundersTimelock
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 */
contract FoundersTimelock is Ownable {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);

    // beneficiary of tokens after they are released
    address private immutable _beneficiary;

    // ERC20 basic token contract being held
    IERC20 private immutable _token;

    uint256 private immutable _cliff; // cliff period in seconds
    uint256 private immutable _vestingPeriod; // ie: 1 month
    uint8 private immutable _vestingDuration; // ie: 10 (vesting will last for 10 months and release linearly every month)

    uint256 private _released = 0;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param token_ ERC20 basic token contract being held
     * @param beneficiary_ address of the beneficiary to whom vested tokens are transferred
     * @param cliffDuration_ duration in seconds of the cliff in which tokens will begin to vest
     * @param vestingPeriod_ the frequency (as Unix time) at which tokens are released
     * @param vestingDuration_ the total count of vesting periods
     */
    constructor (IERC20 token_, address beneficiary_, uint256 cliffDuration_, uint256 vestingPeriod_, uint8 vestingDuration_) {
        require(beneficiary_ != address(0), "FoundersTimelock: beneficiary is the zero address");
        require(vestingPeriod_ > 0, "FoundersTimelock: vestingPeriod is 0");
        require(vestingDuration_ > 0, "FoundersTimelock: vestingDuration is 0");
        require(vestingDuration_ < 256, "FoundersTimelock: vestingDuration is bigger than 255");

        _token = token_;
        _beneficiary = beneficiary_;
        // solhint-disable-next-line not-rely-on-time
        _cliff = block.timestamp.add(cliffDuration_); // safe the use with the 15-seconds rule 
        _vestingPeriod = vestingPeriod_;
        _vestingDuration = vestingDuration_;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() external view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the cliff time of the token vesting.
     */
    function cliff() external view returns (uint256) {
        return _cliff;
    }

    /**
     * @return the vesting frequency of the token vesting.
     */
    function vestingPeriod() external view returns (uint256) {
        return _vestingPeriod;
    }

    /**
     * @return the duration of the token vesting.
     */
    function vestingDuration() external view returns (uint256) {
        return _vestingDuration;
    }

    /**
     * @return the amount of tokens released.
     */
    function releasedBalance() external view returns (uint256) {
        return _released;
    }

    /**
     * @return the amount of tokens still locked
     */
    function lockedBalance() external view returns (uint256) {
        return _token.balanceOf(address(this));
    }


    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() external {
        require (msg.sender == _beneficiary, "FoundersTimelock: only beneficiary can release tokens");

        uint256 unreleased = _releasableAmount();

        require(unreleased > 0, "FoundersTimelock: no tokens are due");

        _released = _released + unreleased;

        _token.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(address(_token), unreleased);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     */
    function _releasableAmount() private view returns (uint256) {
        return _vestedAmount().sub(_released);
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount() private view returns (uint256) {
        uint256 currentBalance = _token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released);

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _cliff.add(_vestingDuration * _vestingPeriod)) { // solhint-disable-line not-rely-on-time
            return totalBalance;
        } else {
            // Vesting period
            uint256 vestingElapsed = block.timestamp.sub(_cliff);
            uint256 vestingStep = (vestingElapsed / _vestingPeriod) + 1; // Round up
            if(vestingStep > _vestingDuration) {
                vestingStep = _vestingDuration;
            }
            return totalBalance.mul(vestingStep).div(_vestingDuration);
        }
    }
}