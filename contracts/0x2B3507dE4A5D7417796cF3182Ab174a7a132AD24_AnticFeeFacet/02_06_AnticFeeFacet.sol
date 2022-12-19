//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IAnticFee} from "../../interfaces/IAnticFee.sol";
import {LibAnticFee} from "../../libraries/LibAnticFee.sol";

/// @author Amit Molek
/// @dev Please see `IAnticFee` for docs
contract AnticFeeFacet is IAnticFee {
    function antic() external view override returns (address) {
        return LibAnticFee._antic();
    }

    function calculateAnticJoinFee(uint256 value)
        external
        view
        override
        returns (uint256)
    {
        return LibAnticFee._calculateAnticJoinFee(value);
    }

    function calculateAnticSellFee(uint256 value)
        external
        view
        override
        returns (uint256)
    {
        return LibAnticFee._calculateAnticSellFee(value);
    }

    function anticFeePercentages()
        external
        view
        override
        returns (uint16 joinFeePercentage, uint16 sellFeePercentage)
    {
        return LibAnticFee._anticFeePercentages();
    }

    /// @return the total Antic join fee deposited
    function totalJoinFeeDeposits() external view returns (uint256) {
        return LibAnticFee._totalJoinFeeDeposits();
    }

    /// @return the antic fee deposit made by `member`
    function memberAnticFeeDeposits(address member)
        external
        view
        returns (uint256)
    {
        return LibAnticFee._memberFeeDeposits(member);
    }
}