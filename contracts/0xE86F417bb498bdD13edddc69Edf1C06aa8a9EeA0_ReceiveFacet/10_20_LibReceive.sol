//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibAnticFee} from "./LibAnticFee.sol";
import {LibOwnership} from "./LibOwnership.sol";
import {StorageReceive} from "../storage/StorageReceive.sol";
import {LibTransfer} from "./LibTransfer.sol";
import {LibDeploymentRefund} from "./LibDeploymentRefund.sol";

/// @author Amit Molek
/// @dev Please see `IReceive` for docs
library LibReceive {
    event ValueWithdrawn(address member, uint256 value);
    event ValueReceived(address from, uint256 value);

    function _receive() internal {
        uint256 value = msg.value;

        emit ValueReceived(msg.sender, value);

        uint256 anticFee = LibAnticFee._calculateAnticSellFee(value);
        uint256 remainingValue = value - anticFee;

        _splitValueToMembers(remainingValue);
        LibAnticFee._untrustedTransferToAntic(anticFee);
    }

    /// @dev Splits `value` to the group members, based on their ownership units
    function _splitValueToMembers(uint256 value) internal {
        uint256 memberCount = LibOwnership._memberCount();
        uint256 totalOwnershipUnits = LibOwnership._totalOwnershipUnits();

        StorageReceive.DiamondStorage storage ds = StorageReceive
            .diamondStorage();

        // Iterate over all the group members and split the incoming funds to them.
        // *Based on their ownership units
        uint256 total = 0;
        for (uint256 i = 0; i < memberCount; i++) {
            (address member, uint256 units) = LibOwnership._memberAt(i);

            uint256 withdrawablePortion = (value * units) / totalOwnershipUnits;
            ds.withdrawable[member] += withdrawablePortion;
            total += withdrawablePortion;
        }

        // The loss of precision in the split calculation
        // can lead to trace funds unavailable to claim. So we tip
        // the deployer with the remainder
        if (value > total) {
            uint256 deployerTip = value - total;
            address deployer = LibDeploymentRefund._deployer();

            ds.withdrawable[deployer] += deployerTip;
        }

        // Update the total withdrawable amount by members.
        ds.totalWithdrawable += value;
    }

    /// @dev Transfer collected funds to the calling member
    /// Emits `ValueWithdrawn`
    function _withdraw() internal {
        address account = msg.sender;

        require(LibOwnership._isMember(account), "Receive: not a member");

        StorageReceive.DiamondStorage storage ds = StorageReceive
            .diamondStorage();

        uint256 withdrawable = ds.withdrawable[account];
        require(withdrawable > 0, "Receive: nothing to withdraw");

        ds.withdrawable[account] = 0;
        ds.totalWithdrawable -= withdrawable;

        emit ValueWithdrawn(account, withdrawable);

        LibTransfer._untrustedSendValue(payable(account), withdrawable);
    }

    function _withdrawable(address member) internal view returns (uint256) {
        StorageReceive.DiamondStorage storage ds = StorageReceive
            .diamondStorage();

        return ds.withdrawable[member];
    }

    function _totalWithdrawable() internal view returns (uint256) {
        StorageReceive.DiamondStorage storage ds = StorageReceive
            .diamondStorage();

        return ds.totalWithdrawable;
    }
}