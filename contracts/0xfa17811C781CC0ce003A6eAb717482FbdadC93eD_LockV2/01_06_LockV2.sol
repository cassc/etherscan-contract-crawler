// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract LockV2 is Ownable, ReentrancyGuard {
    struct VestingPeriod {
        uint256 startTime;
        uint256 releaseTime;
        uint256 totalTokens;
        uint256 releasedTokens;
        uint256 initialReleaseAmount;

        bool isInitialized;
    }

    // Address of the token contract
    address public tokenContract;

    // Address of the beneficiary who will receive the tokens
    address public beneficiary;

    VestingPeriod public vesting;

    // Constructor
    constructor(
        address _tokenContract,
        address _beneficiary,
        uint256 _totalTokens
    ) {
        tokenContract = _tokenContract;
        beneficiary = _beneficiary;

        // initilize the vesting data
        vesting.startTime = 0;
        vesting.releaseTime = 0;
        vesting.totalTokens = _totalTokens;
        vesting.releasedTokens = 0;
        vesting.initialReleaseAmount = _totalTokens * 10 / 100; // 10% of the total tokens
        vesting.isInitialized = false;
    }

    function startVesting() external onlyOwner {
        require(!vesting.isInitialized, "Vesting already initialized");

        vesting.startTime = block.timestamp;
        vesting.releaseTime = block.timestamp + 365 days;
        vesting.isInitialized = true;

        IERC20(tokenContract).transferFrom(msg.sender, address(this), vesting.totalTokens);
    }

    function releaseInitialTokens() external nonReentrant {
        require(msg.sender == beneficiary, "You aren't the beneficiary");
        require(vesting.isInitialized, "Vesting period not initialized");
        require(vesting.initialReleaseAmount > 0, "Initial tokens already released");

        uint256 amountToRelease = vesting.initialReleaseAmount;

        vesting.releasedTokens += amountToRelease;
        vesting.initialReleaseAmount = 0;

        IERC20(tokenContract).transfer(beneficiary, amountToRelease);
    }

    // Function to release tokens after the lock-up period
    function releaseTokens() external nonReentrant returns (bool) {
        require(msg.sender == beneficiary, "You aren't the beneficiary");
        require(vesting.isInitialized, "Vesting period not initialized");
        require(block.timestamp >= vesting.releaseTime, "Tokens are still locked.");
        require(vesting.releasedTokens < vesting.totalTokens, "All tokens already released");

        uint256 amountToRelease = vesting.totalTokens - vesting.releasedTokens;
        vesting.releasedTokens += amountToRelease;
        // update the initialReleaseAmount state in case the beneficiary did not release it yet
        vesting.initialReleaseAmount = 0;

        IERC20(tokenContract).transfer(beneficiary, amountToRelease);

        return true;
    }
}