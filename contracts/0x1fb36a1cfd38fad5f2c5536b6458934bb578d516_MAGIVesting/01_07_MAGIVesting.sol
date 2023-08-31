// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MAGIVesting is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;

    uint public startTime;
    uint public duration;
    uint public tgeUnlock; // BASE  1000
    uint constant TGE_UNLOCK_BASE = 1000;

    mapping(address => uint) public allocation;
    mapping(address => uint) public claimed;

    uint public totalAllocation;
    uint public totalClaimed;

    constructor(
        IERC20 token_,
        uint startTime_,
        uint duration_,
        uint tgeUnlock_
    ) {
        require(tgeUnlock_ < TGE_UNLOCK_BASE);

        token = token_;
        startTime = startTime_;
        duration = duration_;
        tgeUnlock = tgeUnlock_;
    }

    function claim() external {
        require(block.timestamp >= startTime, "LinearVesting: has not started");
        uint amount = _available(msg.sender);
        token.safeTransfer(msg.sender, amount);
        claimed[msg.sender] += amount;
        totalClaimed += amount;
    }

    function available(address address_) external view returns (uint) {
        return _available(address_);
    }

    function released(address address_) external view returns (uint) {
        return _released(address_);
    }

    function outstanding(address address_) external view returns (uint) {
        return allocation[address_] - _released(address_);
    }

    // add vesting allocation
    function addAllocations(
        address[] memory recipients_,
        uint[] memory allocations_
    ) external onlyOwner {
        for (uint i = 0; i < recipients_.length; i++) {
            totalAllocation =
                totalAllocation +
                allocations_[i] -
                allocation[recipients_[i]];
            allocation[recipients_[i]] = allocations_[i];
        }
    }

    // get stuck token
    function withdrawStuckToken(
        address _token,
        address _to
    ) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }

    function _available(address address_) internal view returns (uint) {
        return _released(address_) - claimed[address_];
    }

    function _released(address address_) internal view returns (uint) {
        if (block.timestamp < startTime) {
            return 0;
        } else {
            if (block.timestamp > startTime + duration) {
                return allocation[address_];
            } else {
                uint unlockedAtTGE = (allocation[address_] * tgeUnlock) /
                    TGE_UNLOCK_BASE;
                uint lockedAtTGE = allocation[address_] - unlockedAtTGE;

                return
                    unlockedAtTGE +
                    (lockedAtTGE * (block.timestamp - startTime)) /
                    duration;
            }
        }
    }
}