//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibTransfer} from "./LibTransfer.sol";
import {StorageAnticFee} from "../storage/StorageAnticFee.sol";

/// @author Amit Molek
/// @dev Please see `IAnticFee` for docs
library LibAnticFee {
    event TransferredToAntic(uint256 amount);

    function _antic() internal view returns (address) {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return ds.antic;
    }

    /// @return The amount of fee collected so far from `join`
    function _totalJoinFeeDeposits() internal view returns (uint256) {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return ds.totalJoinFeeDeposits;
    }

    function _calculateAnticJoinFee(uint256 value)
        internal
        view
        returns (uint256)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return
            (value * ds.joinFeePercentage) / StorageAnticFee.PERCENTAGE_DIVIDER;
    }

    function _calculateAnticSellFee(uint256 value)
        internal
        view
        returns (uint256)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return
            (value * ds.sellFeePercentage) / StorageAnticFee.PERCENTAGE_DIVIDER;
    }

    /// @dev Store `member`'s join fee
    function _depositJoinFeePayment(address member, uint256 value) internal {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        ds.memberFeeDeposits[member] += value;
        ds.totalJoinFeeDeposits += value;
    }

    /// @dev Removes `member` from fee collection
    /// @return amount The amount that needs to be refunded to `member`
    function _refundFeePayment(address member)
        internal
        returns (uint256 amount)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        amount = ds.memberFeeDeposits[member];
        ds.totalJoinFeeDeposits -= amount;
        delete ds.memberFeeDeposits[member];
    }

    /// @dev Transfer `value` to Antic
    function _untrustedTransferToAntic(uint256 value) internal {
        emit TransferredToAntic(value);

        LibTransfer._untrustedSendValue(payable(_antic()), value);
    }

    /// @dev Transfer all the `join` fees collected to Antic
    function _untrustedTransferJoinAnticFee() internal {
        _untrustedTransferToAntic(_totalJoinFeeDeposits());
    }

    function _anticFeePercentages()
        internal
        view
        returns (uint16 joinFeePercentage, uint16 sellFeePercentage)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        joinFeePercentage = ds.joinFeePercentage;
        sellFeePercentage = ds.sellFeePercentage;
    }

    function _memberFeeDeposits(address member)
        internal
        view
        returns (uint256)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return ds.memberFeeDeposits[member];
    }
}