/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface IFee {
    /// @notice decrease the fee base
    /// @param baseFee will be decreased
    /// @dev minus the fee base funding
    function decreaseBaseFeeFunding(uint256 baseFee) external;

    /// @notice decrease the fee quote
    /// @param quoteFee will be decreased
    /// @dev minus the fee quote funding
    function decreaseQuoteFeeFunding(uint256 quoteFee) external;

    /// @notice increase the fee base
    /// @param baseFee will be decreased
    /// @dev plus the fee base funding
    function increaseBaseFeeFunding(uint256 baseFee) external;

    /// @notice increase the fee quote`
    /// @param quoteFee will be decreased
    /// @dev plus the fee quote funding
    function increaseQuoteFeeFunding(uint256 quoteFee) external;

    /// @notice reset the fee funding to zero when Position claim fee
    /// @param baseFee will be decreased
    /// @param quoteFee will be decreased
    /// @dev reset baseFee and quoteFee to zero
    function resetFee(uint256 baseFee, uint256 quoteFee) external;

    /// @notice get the fee base funding and fee quote funding
    /// @dev load amount quote and base
    /// @return baseFeeFunding and quoteFeeFunding
    function getFee()
        external
        view
        returns (uint256 baseFeeFunding, uint256 quoteFeeFunding);
}