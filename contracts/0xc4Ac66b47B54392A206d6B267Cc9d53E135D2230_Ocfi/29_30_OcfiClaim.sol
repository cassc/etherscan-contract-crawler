// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Ocfi.sol";
import "./OcfiDividendTracker.sol";
import "./Ownable.sol";

contract OcfiClaim is Ownable {
    Ocfi token;
    OcfiDividendTracker dividendTracker;

    uint256 private constant FACTOR_MAX = 10000;

    mapping (address => ClaimInfo) public claimInfo;

    uint256 private totalTokens;

    struct ClaimInfo {
        uint128 totalClaimAmount;
        uint128 totalClaimed;
        uint64 startTime;
        uint64 factor;
        uint64 period;
        uint64 expiryDuration;
    }

    event ClaimSet(
        address account,
        uint128 totalClaimAmount,
        uint64 startTime,
        uint64 factor,
        uint64 period,
        uint64 expiryDuration
    );

    event ClaimRemoved(
        address account
    );

    event Claim(
        address indexed account,
        uint256 amount
    );

    constructor(address _token, address _dividendTracker) {
        token = Ocfi(payable(_token));
        dividendTracker = OcfiDividendTracker(payable(_dividendTracker));
    }

    function setClaimInfo(address account, uint256 amount, uint256 factor, uint256 period, uint256 expiryDuration) public onlyOwner {
        ClaimInfo storage info = claimInfo[account];

        require(amount > 0, "Invalid amount");
        require(info.totalClaimAmount == 0, "This account has an active claim");

        info.totalClaimAmount = uint128(amount);
        info.startTime = uint64(block.timestamp);
        info.factor = uint64(factor);
        info.period = uint64(period);
        info.expiryDuration = uint64(expiryDuration);

        totalTokens += amount;

        token.transferFrom(owner(), address(this), amount);

        dividendTracker.updateAccountBalance(account);

        emit ClaimSet(account, info.totalClaimAmount, info.startTime, info.factor, info.period, info.expiryDuration);
    }

    function setClaimInfos(address[] memory account, uint256[] memory amount, uint256[] memory factor, uint256[] memory period, uint256[] memory expiryDuration) external onlyOwner {
        require(account.length == amount.length);
        require(account.length == factor.length);
        require(account.length == period.length);
        require(account.length == expiryDuration.length);

        for(uint256 i = 0; i < account.length; i++) {
            setClaimInfo(account[i], amount[i], factor[i], period[i], expiryDuration[i]);
        }
    }

    function removeClaimInfo(address account) external onlyOwner {
        ClaimInfo storage info = claimInfo[account];

        require(info.totalClaimAmount > 0);

        uint256 unclaimed = info.totalClaimAmount - info.totalClaimed;
        token.transfer(owner(), unclaimed);
        totalTokens -= unclaimed;

        delete claimInfo[account];

        dividendTracker.updateAccountBalance(account);

        emit ClaimRemoved(account);
    }

    function getClaimExpired(ClaimInfo storage info) private view returns (bool) {
        if(info.totalClaimAmount == 0) {
            return false;
        }

        uint256 startTime = token.startTime();

        if(startTime == 0) {
            return false;
        }

        if(info.startTime > startTime) {
            startTime = info.startTime;
        }

        uint256 elapsed = block.timestamp - startTime;
        return info.expiryDuration > 0 && elapsed >= info.expiryDuration;
    }

    //returns how much the user can currently claim, as well as if it's the final claim
    function getTotalClaimAvailable(ClaimInfo storage info) private view returns (uint256, bool) {
        if(info.totalClaimAmount == 0) {
            return (0, false);
        }

        uint256 startTime = token.startTime();

        if(startTime == 0) {
            return (0, false);
        }

        if(info.startTime > startTime) {
            startTime = info.startTime;
        }

        uint256 elapsed = block.timestamp - startTime;

        uint256 periodsElapsed = elapsed / info.period;

        bool isFinal = periodsElapsed * info.factor >= FACTOR_MAX;

        uint256 claimAvailable = info.totalClaimAmount * periodsElapsed * info.factor / FACTOR_MAX - info.totalClaimed;

        if(claimAvailable > info.totalClaimAmount - info.totalClaimed) {
            claimAvailable = info.totalClaimAmount - info.totalClaimed;
        }

        return (claimAvailable, isFinal);
    }


    function claim() public {
        require(token.startTime() > 0, "Token has not started trading yet");

        address account = msg.sender;

        ClaimInfo storage info = claimInfo[account];

        require(!getClaimExpired(info), "Claim has expired");

        (uint256 totalClaimAvailable, bool isFinal) = getTotalClaimAvailable(info);
        require(totalClaimAvailable > 0);

        claimOcfiDividends();

        if(isFinal) {
            totalClaimAvailable = info.totalClaimAmount - info.totalClaimed;
        }
  
        info.totalClaimed += uint128(totalClaimAvailable);
        token.transfer(account, totalClaimAvailable);
        totalTokens -= totalClaimAvailable;

        dividendTracker.updateAccountBalance(account);

        emit Claim(account, totalClaimAvailable);
    }

    function claimOcfiDividends() public {
        token.claimDividends(false);
    }

    function withdrawExcess() external onlyOwner {
        uint256 excess = token.balanceOf(address(this)) - totalTokens;

        if(excess > 0) {
            token.transfer(owner(), excess);
        }
    }

    function getClaimInfo(address account) external view returns (ClaimInfo memory info, uint256 totalClaimAvailable, bool isFinal, bool expired) {
        ClaimInfo storage storageClaim = claimInfo[account];

        info = storageClaim;
        (totalClaimAvailable, isFinal) = getTotalClaimAvailable(storageClaim);
        expired = getClaimExpired(storageClaim);
    }

    //returns how many tokens the user still has unclaimed, whether it is available or not
    function getTotalClaimRemaining(address account) external view returns (uint256) {
        ClaimInfo storage info = claimInfo[account];

        return info.totalClaimAmount - info.totalClaimed;
    }
}