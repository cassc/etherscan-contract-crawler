// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IRLBTRFLY} from "./interfaces/IRLBTRFLY.sol";

contract PirexBtrflyBase is Ownable, Pausable {
    using SafeTransferLib for ERC20;

    ERC20 public immutable btrflyV2;

    // Address of the BTRFLYV2 locker (rlBTRFLY)
    IRLBTRFLY public rlBtrfly;

    // The amount of BTRFLYV2 that needs to remain unlocked for redemptions
    uint256 public outstandingRedemptions;

    // The amount of BTRFLYV2 (claimed as rewards) that should not be locked
    uint256 public pendingBaseRewards;

    // The amount of new BTRFLYV2 deposits that is awaiting lock
    uint256 public pendingLocks;

    event SetLocker(address _rlBtrfly);

    error ZeroAddress();
    error EmptyString();

    /**
        @param  _btrflyV2  address  BTRFLYV2 address
        @param  _rlBtrfly  address  rlBTRFLY address
     */
    constructor(address _btrflyV2, address _rlBtrfly) {
        if (_btrflyV2 == address(0)) revert ZeroAddress();
        if (_rlBtrfly == address(0)) revert ZeroAddress();

        btrflyV2 = ERC20(_btrflyV2);
        rlBtrfly = IRLBTRFLY(_rlBtrfly);

        // Max allowance for rlBTRFLY
        btrflyV2.safeApprove(address(rlBtrfly), type(uint256).max);
    }

    /** 
        @notice Set the locker (rlBTRFLY) address
        @param  _rlBtrfly  address  rlBTRFLY address
     */
    function setLocker(address _rlBtrfly) external onlyOwner {
        if (_rlBtrfly == address(0)) revert ZeroAddress();

        emit SetLocker(_rlBtrfly);

        btrflyV2.safeApprove(address(rlBtrfly), 0);

        rlBtrfly = IRLBTRFLY(_rlBtrfly);

        btrflyV2.safeApprove(_rlBtrfly, type(uint256).max);
    }

    /**
        @notice Unlock BTRFLYV2
     */
    function _unlock() internal {
        (, uint256 unlockable, , ) = rlBtrfly.lockedBalances(address(this));

        if (unlockable != 0) rlBtrfly.processExpiredLocks(false);
    }

    /**
        @notice Unlock BTRFLYV2 and relock excess
     */
    function _lock() internal {
        _unlock();

        // Should not include pendingBaseRewards
        uint256 balance = btrflyV2.balanceOf(address(this)) - pendingBaseRewards;
        bool balanceGreaterThanRedemptions = balance > outstandingRedemptions;

        // Lock BTRFLYV2 if the balance is greater than outstanding redemptions or if there are pending locks
        if (balanceGreaterThanRedemptions || pendingLocks != 0) {
            uint256 balanceRedemptionsDifference = balanceGreaterThanRedemptions
                ? balance - outstandingRedemptions
                : 0;

            // Lock amount is the greater of the two: balanceRedemptionsDifference or pendingLocks
            // balanceRedemptionsDifference is greater if there is unlocked BTRFLYV2 that isn't reserved for redemptions + deposits
            // pendingLocks is greater if there are more new deposits than unlocked BTRFLYV2 that is reserved for redemptions
            rlBtrfly.lock(
                address(this),
                balanceRedemptionsDifference > pendingLocks
                    ? balanceRedemptionsDifference
                    : pendingLocks
            );

            pendingLocks = 0;
        }
    }

    /**
        @notice Non-permissioned relock method
     */
    function lock() external whenNotPaused {
        _lock();
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY/MIGRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /** 
        @notice Set the contract's pause state
        @param state  bool  Pause state
    */
    function setPauseState(bool state) external onlyOwner {
        if (state) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
        @notice Manually unlock BTRFLYV2 in the case of a mass unlock
     */
    function unlock() external whenPaused onlyOwner {
        rlBtrfly.processExpiredLocks(false);
    }

    /**
        @notice Manually relock BTRFLYV2 with a new rlBTRFLY contract
     */
    function pausedRelock() external whenPaused onlyOwner {
        _lock();
    }
}