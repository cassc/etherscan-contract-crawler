// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Claimer is Ownable {
    using SafeERC20 for IERC20;

    struct Claim {
        uint unlockTime; // unix time
        uint percent; // three decimals: 1.783% = 1783
    }

    Claim[] public claims;

    string public id;

    bool public isPaused = false;
    uint public totalTokens;
    uint public claimedTokens;
    mapping(address => uint) public total;
    mapping(address => uint) public claimed;
    mapping(address => mapping(uint => uint)) public isClaimed;

    IERC20 public token;

    event Claimed(address indexed account, uint amount, uint percent, uint claimIdx);
    event ClaimReleased(uint percent, uint newTime, uint claimIdx);
    event ClaimDelayed(uint percent, uint newTime, uint claimIdx);
    event ClaimingPaused(bool status);

    constructor(string memory _id, address _token, uint[] memory times, uint[] memory percents) {
        token = IERC20(_token);
        id = _id;

        uint totalPercent;
        for (uint i = 0; i < times.length; i++) {
            require(percents[i] > 0, 'Claimer: 0% is not allowed');
            require(times[i] > 0, 'Claimer: time must specified');

            claims.push(Claim(times[i], percents[i]));
            totalPercent += percents[i];
        }
        require(totalPercent == 100000, 'Claimer: Sum of all claimed must be 100%');
    }

    function getClaimableAccountAmount(address account) external view returns (uint) {
        uint totalClaimable;
        for (uint i = 0; i < claims.length; i++) {
            if (isClaimable(i)) {
                totalClaimable += getClaimAmount(i, account);
            }
        }

        return totalClaimable - claimed[account];
    }

    function getAccountAmount(address account) external view returns (uint) {
        return total[account];
    }

    function getRemainingAccountAmount(address account) external view returns (uint) {
        return total[account] - claimed[account];
    }

    function getTotalRemainingAmount() external view returns (uint) {
        return totalTokens - claimedTokens;
    }

    function getClaims(address account) external view returns (uint[] memory, uint[] memory, uint[] memory, bool[] memory, uint[] memory) {
        uint len = claims.length;
        uint[] memory times = new uint[](len);
        uint[] memory percents = new uint[](len);
        uint[] memory amount = new uint[](len);
        bool[] memory _isClaimable = new bool[](len);
        uint[] memory claimedAmount = new uint[](len);

        for (uint i = 0; i < len; i++) {
            times[i] = claims[i].unlockTime;
            percents[i] = claims[i].percent;
            amount[i] = getClaimAmount(i, account);
            _isClaimable[i] = block.timestamp > claims[i].unlockTime;
            claimedAmount[i] = isClaimed[account][i];
        }

        return (times, percents, amount, _isClaimable, claimedAmount);
    }

    function claim(address account, uint idx) external {
        require(idx < claims.length, "Claimer: Out of bounds index");
        require(total[account] > 0, "Claimer: Account doesn't have allocation");
        require(!isPaused, "Claimer: Claiming paused");

        uint claimAmount = claimInternal(account, idx);
        emit Claimed(account, claimAmount, claims[idx].percent, idx);
    }

    function claimAll(address account) external {
        require(total[account] > 0, "Claimer: Account doesn't have allocation");
        require(!isPaused, "Claimer: Claiming paused");

        for (uint idx = 0; idx < claims.length; idx++) {
            if (isClaimed[account][idx] == 0 && isClaimable(idx)) {
                claimInternal(account, idx);
            }
        }
    }

    function claimInternal(address account, uint idx) internal returns (uint) {
        require(isClaimed[account][idx] == 0, "Claimer: Already claimed");
        require(isClaimable(idx), "Claimer: Not claimable");

        uint claimAmount = getClaimAmount(idx, account);
        require(claimAmount > 0, "Claimer: Amount is zero");

        claimedTokens += claimAmount;
        claimed[account] += claimAmount;
        isClaimed[account][idx] = claimAmount;

        token.safeTransfer(account, claimAmount);

        return claimAmount;
    }

    function releaseClaim(uint claimIdx) external onlyOwner {
        require(claimIdx < claims.length, "Claimer: Out of bounds index");
        Claim storage _claim = claims[claimIdx];

        require(_claim.unlockTime > block.timestamp, 'Claimer: Claim already released');
        _claim.unlockTime = block.timestamp;
        emit ClaimReleased(_claim.percent, _claim.unlockTime, claimIdx);
    }

    function delayClaim(uint claimIdx, uint newUnlockTime) external onlyOwner {
        require(claimIdx < claims.length, "Claimer: Out of bounds index");
        Claim storage _claim = claims[claimIdx];

        require(newUnlockTime > block.timestamp, 'Claimer: Time must be in future');
        require(newUnlockTime > _claim.unlockTime, 'Claimer: Time must be after the current claim time');
        _claim.unlockTime = newUnlockTime;
        emit ClaimDelayed(_claim.percent, _claim.unlockTime, claimIdx);
    }

    function isClaimable(uint claimIdx) internal view returns (bool) {
        return claims[claimIdx].unlockTime < block.timestamp;
    }

    function getClaimAmount(uint claimIdx, address account) internal view returns (uint) {
        if (total[account] == 0) {
            return 0;
        }

        return total[account] * claims[claimIdx].percent / 100000;
    }

    function pauseClaiming(bool status) external onlyOwner {
        isPaused = status;
        emit ClaimingPaused(status);
    }

    function setAllocation(address account, uint newTotal) external onlyOwner {
        if (newTotal > total[account]) {
            totalTokens += newTotal - total[account];
        } else {
            totalTokens -= total[account] - newTotal;
        }
        total[account] = newTotal;
    }

    function batchAddAllocation(address[] calldata addresses, uint[] calldata allocations) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            address account = addresses[i];
            if (total[account] > 0) {
                continue;
            }
            total[account] = allocations[i];
            totalTokens += allocations[i];
        }
    }

    function batchMarkClaimed(address[] calldata addresses, uint[] calldata claimedIdx) external onlyOwner {
        for (uint i = 0; i < claimedIdx.length; i++) {
            uint idx = claimedIdx[i];

            for (uint j = 0; j < addresses.length; j++) {
                address account = addresses[j];
                uint claimAmount = getClaimAmount(idx, account);

                claimedTokens += claimAmount;
                claimed[account] += claimAmount;
                isClaimed[account][idx] = claimAmount;
                emit Claimed(account, claimAmount, claims[idx].percent, idx);
            }
        }
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }

        token.transfer(owner(), token.balanceOf(address(this)));
    }

    function withdrawToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(owner(), amount);
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }
}