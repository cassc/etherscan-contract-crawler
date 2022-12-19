//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Antic fee collector address provider interface
/// @author Amit Molek
interface IAnticFeeCollectorProvider {
    /// @dev Emitted on transfer of the Antic's fee collector address
    /// @param previousCollector The previous fee collector
    /// @param newCollector The new fee collector
    event AnticFeeCollectorTransferred(
        address indexed previousCollector,
        address indexed newCollector
    );

    /// @dev Emitted on changing the Antic fees
    /// @param oldJoinFee The previous join fee percentage out of 1000
    /// @param newJoinFee The new join fee percentage out of 1000
    /// @param oldSellFee The previous sell fee percentage out of 1000
    /// @param newSellFee The new sell fee percentage out of 1000
    event AnticFeeChanged(
        uint16 oldJoinFee,
        uint16 newJoinFee,
        uint16 oldSellFee,
        uint16 newSellFee
    );

    /// @notice Transfer Antic's fee collector address
    /// @param newCollector The address of the new Antic fee collector
    function transferAnticFeeCollector(address newCollector) external;

    /// @notice Change Antic fees
    /// @param newJoinFee Antic join fee percentage out of 1000
    /// @param newSellFee Antic sell/receive fee percentage out of 1000
    function changeAnticFee(uint16 newJoinFee, uint16 newSellFee) external;

    /// @return The address of Antic's fee collector
    function anticFeeCollector() external view returns (address);

    /// @return joinFee The fee amount in percentage (out of 1000) that Antic takes for joining
    /// @return sellFee The fee amount in percentage (out of 1000) that Antic takes for selling
    function anticFees() external view returns (uint16 joinFee, uint16 sellFee);
}