// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @title meTokens Protocol Fees Facet interface
/// @author Carter Carlson (@cartercarlson)
interface IFeesFacet {
    /// @notice Event of setting the Mint fee for meTokens protocol
    /// @param rate New fee rate
    event SetMintFee(uint256 rate);

    /// @notice Event of setting the BurnBuyer fee for meTokens protocol
    /// @param rate New fee rate
    event SetBurnBuyerFee(uint256 rate);

    /// @notice Event of setting the BurnOwner fee for meTokens protocol
    /// @param rate New fee rate
    event SetBurnOwnerFee(uint256 rate);

    /// @notice Set Mint fee for meTokens protocol
    /// @dev Only callable by FeesController
    /// @param rate New fee rate
    function setMintFee(uint256 rate) external;

    /// @notice Set BurnBuyer fee for meTokens protocol
    /// @dev Only callable by FeesController
    /// @param rate New fee rate
    function setBurnBuyerFee(uint256 rate) external;

    /// @notice Set BurnOwner fee for meTokens protocol
    /// @dev Only callable by FeesController
    /// @param rate New fee rate
    function setBurnOwnerFee(uint256 rate) external;

    /// @notice Get Mint fee
    /// @return uint256 mintFee
    function mintFee() external view returns (uint256);

    /// @notice Get BurnBuyer fee
    /// @return uint256 burnBuyerFee
    function burnBuyerFee() external view returns (uint256);

    /// @notice Get BurnOwner fee
    /// @return uint256 burnOwnerFee
    function burnOwnerFee() external view returns (uint256);
}