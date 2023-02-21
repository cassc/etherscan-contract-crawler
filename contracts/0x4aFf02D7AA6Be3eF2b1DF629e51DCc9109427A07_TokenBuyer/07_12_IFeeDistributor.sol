// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeDistributor {
    /// @notice The base fee of a swap on top of the percentual fee.
    /// @param token The token whose base fee is queried.
    /// @return baseFee The amount of the fee in wei.
    function baseFee(address token) external returns (uint256 baseFee);

    /// @notice Sets the base fee for a given token.
    /// @dev Callable only by the current fee collector.
    /// @param token The token whose base fee is set.
    /// @param newFee The new base fee in wei.
    function setBaseFee(address token, uint256 newFee) external;

    /// @notice Sets the address that receives the fee from the funds.
    /// @dev Callable only by the current fee collector.
    /// @param newFeeCollector The new address of feeCollector.
    function setFeeCollector(address payable newFeeCollector) external;

    /// @notice Sets the fee's amount from the funds.
    /// @dev Callable only by the fee collector.
    /// @param newShare The percentual value expressed in basis points.
    function setFeePercentBps(uint96 newShare) external;

    /// @notice Returns the address that receives the fee from the funds.
    function feeCollector() external view returns (address payable);

    /// @notice Returns the percentage of the fee expressed in basis points.
    function feePercentBps() external view returns (uint96);

    /// @notice Event emitted when a token's base fee is changed.
    /// @param token The address of the token whose fee was changed. 0 for ether.
    /// @param newFee The new amount of base fee in wei.
    event BaseFeeChanged(address token, uint256 newFee);

    /// @notice Event emitted when the fee collector address is changed.
    /// @param newFeeCollector The new address of feeCollector.
    event FeeCollectorChanged(address newFeeCollector);

    /// @notice Event emitted when the share of the fee collector changes.
    /// @param newShare The new value of feePercentBps.
    event FeePercentBpsChanged(uint96 newShare);

    /// @notice Error thrown when a function is attempted to be called by the wrong address.
    /// @param sender The address that sent the transaction.
    /// @param owner The address that is allowed to call the function.
    error AccessDenied(address sender, address owner);
}