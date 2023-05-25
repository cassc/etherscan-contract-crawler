/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2022 Coinbase, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.6;

import { Ownable } from "@openzeppelin4.2.0/contracts/access/Ownable.sol";

/**
 * @title RateLimit
 * @dev Rate limiting contract for function calls
 */
contract RateLimit is Ownable {
    /**
     * @dev Mapping denoting caller addresses
     * @return Boolean denoting whether the given address is a caller
     */
    mapping(address => bool) public callers;

    /**
     * @dev Mapping denoting caller address rate limit intervals
     * @return A time in seconds representing the duration of the given callers interval
     */
    mapping(address => uint256) public intervals;

    /**
     * @dev Mapping denoting when a given caller's allowance was last updated
     * @return The time in seconds since a given caller's allowance was last updated
     */
    mapping(address => uint256) public allowancesLastSet;

    /**
     * @dev Mapping denoting a given caller's maximum allowance
     * @return The maximum allowance of a given caller
     */
    mapping(address => uint256) public maxAllowances;

    /**
     * @dev Mapping denoting a given caller's stored allowance
     * @return The stored allowance of a given caller
     */
    mapping(address => uint256) public allowances;

    /**
     * @notice Emitted on caller configuration
     * @param caller The address configured to make rate limited calls
     * @param amount The maximum allowance for the given caller
     * @param interval The amount of time in seconds before a caller's allowance is replenished
     */
    event CallerConfigured(
        address indexed caller,
        uint256 amount,
        uint256 interval
    );

    /**
     * @notice Emitted on caller removal
     * @param caller The address of the caller being removed
     */
    event CallerRemoved(address indexed caller);

    /**
     * @notice Emitted on caller allowance replenishment
     * @param caller The address of the caller whose allowance is being replenished
     * @param allowance The current allowance for the given caller post replenishment
     * @param amountReplenished The allowance amount that was replenished for the given caller
     */
    event AllowanceReplenished(
        address indexed caller,
        uint256 allowance,
        uint256 amountReplenished
    );

    /**
     * @dev Throws if called by any account other than a caller
     * @dev Rate limited functionality in inheriting contracts must have the only caller modifier
     */
    modifier onlyCallers() {
        require(callers[msg.sender], "RateLimit: caller is not whitelisted");
        _;
    }

    /**
     * @dev Function to add/update a new caller. Also updates allowancesLastSet for that caller.
     * @param caller The address of the caller
     * @param amount The call amount allowed for the caller for a given interval
     * @param interval The interval for a given caller
     */
    function configureCaller(
        address caller,
        uint256 amount,
        uint256 interval
    ) external onlyOwner {
        require(caller != address(0), "RateLimit: caller is the zero address");
        require(amount > 0, "RateLimit: amount is zero");
        require(interval > 0, "RateLimit: interval is zero");
        callers[caller] = true;
        maxAllowances[caller] = allowances[caller] = amount;
        allowancesLastSet[caller] = block.timestamp;
        intervals[caller] = interval;
        emit CallerConfigured(caller, amount, interval);
    }

    /**
     * @dev Function to remove a caller.
     * @param caller The address of the caller
     */
    function removeCaller(address caller) external onlyOwner {
        delete callers[caller];
        delete intervals[caller];
        delete allowancesLastSet[caller];
        delete maxAllowances[caller];
        delete allowances[caller];
        emit CallerRemoved(caller);
    }

    /**
     * @dev Helper function to calculate the estimated allowance given caller address
     * @param caller The address whose call allowance is being estimated
     * @return The allowance of the given caller if their allowance were to be replenished
     */
    function estimatedAllowance(address caller)
        external
        view
        returns (uint256)
    {
        return allowances[caller] + _getReplenishAmount(caller);
    }

    /**
     * @dev Get the current caller allowance for an account
     * @param caller The address of the caller
     * @return The allowance of the given caller post replenishment
     */
    function currentAllowance(address caller) public returns (uint256) {
        _replenishAllowance(caller);
        return allowances[caller];
    }

    /**
     * @dev Helper function to replenish a caller's allowance over the interval in proportion to time elapsed, up to their maximum allowance
     * @param caller The address whose allowance is being updated
     */
    function _replenishAllowance(address caller) internal {
        if (allowances[caller] == maxAllowances[caller]) {
            return;
        }
        uint256 amountToReplenish = _getReplenishAmount(caller);
        if (amountToReplenish == 0) {
            return;
        }

        allowances[caller] = allowances[caller] + amountToReplenish;
        allowancesLastSet[caller] = block.timestamp;
        emit AllowanceReplenished(
            caller,
            allowances[caller],
            amountToReplenish
        );
    }

    /**
     * @dev Helper function to calculate the replenishment amount
     * @param caller The address whose allowance is being estimated
     * @return The allowance amount to be replenished for the given caller
     */
    function _getReplenishAmount(address caller)
        internal
        view
        returns (uint256)
    {
        uint256 secondsSinceAllowanceSet = block.timestamp -
            allowancesLastSet[caller];

        uint256 amountToReplenish = (secondsSinceAllowanceSet *
            maxAllowances[caller]) / intervals[caller];
        uint256 allowanceAfterReplenish = allowances[caller] +
            amountToReplenish;

        if (allowanceAfterReplenish > maxAllowances[caller]) {
            amountToReplenish = maxAllowances[caller] - allowances[caller];
        }
        return amountToReplenish;
    }
}