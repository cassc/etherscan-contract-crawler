/**
 *Submitted for verification at Etherscan.io on 2023-08-23
*/

/*
 * -----------------------------------------------
 * ASET Token Lock for Team
 * 
 * Description: A contract to manage the locked tokens for ASET team & co.
 * Tokens are locked for 2 years, then released 25% every 3 months. This is AssetLink's commitment to its investors.
 *
 * Author: Tech Department / AssetLink
 * Version: 1.0.0
 * License: MIT
 * Date: 2023-08-01
 * -----------------------------------------------
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
contract ASETTeamAdvisorsLock {
    address public beneficiary;
    uint256 public initialReleaseTime;
    uint256 public lastReleaseTime;
    IERC20 public token;
    uint256 public releasedPercentage = 0;
    bool public initialized = false;

    // Modifiers
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only the beneficiary can call this function");
        _;
    }

    modifier onlyOnce() {
        require(!initialized, "Already initialized");
        _;
    }

    constructor() {
        beneficiary = msg.sender;
        initialReleaseTime = block.timestamp + 730 days; // Hard-coded to 2 years from now
    }

    function initialize(address _token) external onlyOnce {
        token = IERC20(_token);
        initialized = true;
    }

    function release() public onlyBeneficiary {
        require(initialized, "Contract not initialized");
        require(block.timestamp >= initialReleaseTime, "Tokens are still locked");
        require(releasedPercentage < 100, "All tokens have already been released");

        uint256 monthsSinceLastRelease = (block.timestamp - lastReleaseTime) / 30 days;
        require(monthsSinceLastRelease >= 3, "Less than 3 months since the last release");

        uint256 amountToRelease = (token.balanceOf(address(this)) * 25) / 100; // 25% of the remaining balance
        releasedPercentage += 25;

        lastReleaseTime = block.timestamp;

        require(amountToRelease > 0, "No tokens to release");
        token.transfer(beneficiary, amountToRelease);
    }
}