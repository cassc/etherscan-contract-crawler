//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Antic fee collection
interface IAnticFee {
    /// @dev Emitted on value transfer to Antic
    /// @param amount the amount transferred to Antic
    event TransferredToAntic(uint256 amount);

    /// @return The address that the Antic fees will be sent to
    function antic() external view returns (address);

    /// @return The fee amount that will be collected from
    /// `value` when joining the group
    function calculateAnticJoinFee(uint256 value)
        external
        view
        returns (uint256);

    /// @return The fee amount that will be collected from `value` when
    /// value is transferred to the contract
    function calculateAnticSellFee(uint256 value)
        external
        view
        returns (uint256);

    /// @dev The percentages are out of 1000. So 25 -> 25/1000 = 2.5%
    /// @return joinFeePercentage The Antic fee percentage for join
    /// @return sellFeePercentage The Antic fee percentage for sell/receive
    function anticFeePercentages()
        external
        view
        returns (uint16 joinFeePercentage, uint16 sellFeePercentage);
}