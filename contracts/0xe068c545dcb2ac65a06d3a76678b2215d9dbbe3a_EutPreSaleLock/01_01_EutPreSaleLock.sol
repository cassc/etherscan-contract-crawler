// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract EutPreSaleLock {

    mapping(address => uint256) public initLockAmounts;
    mapping(address => uint256) public releasedAmounts;
    address public immutable eutToken;
    uint256 private constant lockStartTime = 1685577600;
    uint256 private constant cliff = 30 days * 6; // 6-month
    uint256 private constant linearInterval = 30 days;
    uint256 private constant releaseTimes = 12;

    constructor(address eutToken_, uint256 totalLockAmount_, address[] memory accounts_, uint256[] memory amounts_) {
        require(accounts_.length == amounts_.length);
        uint256 totalAmount = 0;
        for (uint i = 0; i < amounts_.length; i++) {
            initLockAmounts[accounts_[i]] += amounts_[i];
            totalAmount += amounts_[i];
        }
        require(totalLockAmount_ == totalAmount);
        eutToken = eutToken_;
    }

    function unlockedAmounts(address account) public view returns(uint256) {
        uint256 eachTimeReleaseAmount = initLockAmounts[account] / releaseTimes;
        require(eachTimeReleaseAmount > 0);
        uint256 timeNow = block.timestamp;
        require(timeNow >= lockStartTime + cliff, "not release time");
        uint256 estimateTimes = (timeNow - (lockStartTime + cliff)) / linearInterval + 1;
        if (estimateTimes >= releaseTimes) {
            return initLockAmounts[account];
        }
        return estimateTimes * eachTimeReleaseAmount;
    }

    function release() external {
        release2Account(msg.sender);
    }

    function release2Account(address account) public {
        uint256 amount2Release = unlockedAmounts(account) - releasedAmounts[account];
        require(amount2Release > 0, "no token to release");
        releasedAmounts[account] += amount2Release;
        IERC20(eutToken).transfer(account, amount2Release);
    }
}