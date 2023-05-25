pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// import "hardhat/console.sol";

/**
 * How all exit of TEMPLE rewards are managed.
 */
contract ExitQueue is Ownable {
    struct User {
        // Total currently in queue
        uint256 Amount;

        // First epoch for which the user is in the unstake queue
        uint256 FirstExitEpoch;

        // Last epoch for which the user has a pending unstake
        uint256 LastExitEpoch;

        // All epochs where the user has an exit allocation
        mapping(uint256 => uint256) Exits;
    }

    // total queued to be exited in a given epoch
    mapping(uint256 => uint256) public totalPerEpoch;

    // The first unwithdrawn epoch for the user
    mapping(address => User) public userData;

    IERC20 public TEMPLE;   // TEMPLE

    // Limit of how much temple can exit per epoch
    uint256 public maxPerEpoch;

    // Limit of how much temple can exit per address per epoch
    uint256 public maxPerAddress;

    // epoch size, in blocks
    uint256 public epochSize; 

    // the block we use to work out what epoch we are in
    uint256 public firstBlock;

    // The next free block on which a user can commence their unstake
    uint256 public nextUnallocatedEpoch;

    event JoinQueue(address exiter, uint256 amount);    
    event Withdrawal(address exiter, uint256 amount);    

    constructor(
        address _TEMPLE,
        uint256 _maxPerEpoch,
        uint256 _maxPerAddress,
        uint256 _epochSize) {

        TEMPLE = IERC20(_TEMPLE);

        maxPerEpoch = _maxPerEpoch;
        maxPerAddress = _maxPerAddress;
        epochSize = _epochSize;
        firstBlock = block.number;
        nextUnallocatedEpoch = 0;
    }

    function setMaxPerEpoch(uint256 _maxPerEpoch) external onlyOwner {
        maxPerEpoch = _maxPerEpoch;
    }

    function setMaxPerAddress(uint256 _maxPerAddress) external onlyOwner {
        maxPerAddress = _maxPerAddress;
    }

    function setEpochSize(uint256 _epochSize) external onlyOwner {
        epochSize = _epochSize;
    }

    function setStartingBlock(uint256 _firstBlock) external onlyOwner {
        require(_firstBlock < firstBlock, "Can only move start block back, not forward");
        firstBlock = _firstBlock;
    }

    function currentEpoch() public view returns (uint256) {
        return (block.number - firstBlock) / epochSize;
    }

    function currentEpochAllocation(address _exiter, uint256 _epoch) external view returns (uint256) {
        return userData[_exiter].Exits[_epoch];
    }

    function join(address _exiter, uint256 _amount) external {        
        require(_amount > 0, "Amount must be > 0");

        if (nextUnallocatedEpoch < currentEpoch()) {
            nextUnallocatedEpoch = currentEpoch();
        }

        User storage user = userData[_exiter];

        uint256 unallocatedAmount = _amount;
        uint256 _nextUnallocatedEpoch = nextUnallocatedEpoch;
        uint256 nextAvailableEpochForUser = _nextUnallocatedEpoch;
        if (user.LastExitEpoch > nextAvailableEpochForUser) {
            nextAvailableEpochForUser = user.LastExitEpoch;
        }

        while (unallocatedAmount > 0) {
            // work out allocation for the next available epoch
            uint256 allocationForEpoch = unallocatedAmount;
            if (user.Exits[nextAvailableEpochForUser] + allocationForEpoch > maxPerAddress) {
                allocationForEpoch = maxPerAddress - user.Exits[nextAvailableEpochForUser];
            }
            if (totalPerEpoch[nextAvailableEpochForUser] + allocationForEpoch > maxPerEpoch) {
                allocationForEpoch = maxPerEpoch - totalPerEpoch[nextAvailableEpochForUser];
            }

            // Bookkeeping
            if (allocationForEpoch > 0) {
                if (user.Amount == 0) {
                    user.FirstExitEpoch = nextAvailableEpochForUser;
                }
                user.Amount += allocationForEpoch;
                user.Exits[nextAvailableEpochForUser] += allocationForEpoch;
                totalPerEpoch[nextAvailableEpochForUser] += allocationForEpoch;
                user.LastExitEpoch = nextAvailableEpochForUser;

                if (totalPerEpoch[nextAvailableEpochForUser] >= maxPerEpoch) {
                    _nextUnallocatedEpoch = nextAvailableEpochForUser;
                }

                unallocatedAmount -= allocationForEpoch;
            }

            nextAvailableEpochForUser += 1;
        }

        // update outside of main loop, so we spend gas once
        nextUnallocatedEpoch = _nextUnallocatedEpoch;

        SafeERC20.safeTransferFrom(TEMPLE, msg.sender, address(this), _amount);
        emit JoinQueue(_exiter, _amount);
    }

    /**
     * Withdraw processed allowance from a specific epoch
     */
    function withdraw(uint256 epoch) external {
        require(epoch < currentEpoch(), "Can only withdraw from past epochs");

        User storage user = userData[msg.sender];

        uint256 amount = user.Exits[epoch];
        delete user.Exits[epoch];
        totalPerEpoch[epoch] -= amount; // TODO: WHen this goes to 0, is it the same as the data being removed?
        user.Amount -= amount;

        // Once all allocations on queue have been claimed, reset user state
        if (user.Amount == 0) {
            // NOTE: triggers ExitQueue.withdraw(uint256) (contracts/ExitQueue.sol #150-167) deletes ExitQueue.User (contracts/ExitQueue.sol#15-27) which contains a mapping
            //        This is okay as if Amount is 0, we'd expect user.Exits to be empty as well
            //        TODO: Confirm this via tests
            delete userData[msg.sender];
        }

        SafeERC20.safeTransfer(TEMPLE, msg.sender, amount);
        emit Withdrawal(msg.sender, amount);    
    }
}