// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title IAsksV1_1
/// @author sweetman.eth <[email protected]>
/// @notice This module allows sellers to list an owned ERC-721 token for sale for a given price in a given currency, and allows buyers to purchase from those asks
interface IAsksV1_1 {
    /// @notice Creates the ask for a given NFT
    /// @param _tokenContract The address of the ERC-721 token to be sold
    /// @param _tokenId The ID of the ERC-721 token to be sold
    /// @param _askPrice The price to fill the ask
    /// @param _askCurrency The address of the ERC-20 token required to fill, or address(0) for ETH
    /// @param _sellerFundsRecipient The address to send funds once the ask is filled
    /// @param _findersFeeBps The bps of the ask price (post-royalties) to be sent to the referrer of the sale
    function createAsk(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _askPrice,
        address _askCurrency,
        address _sellerFundsRecipient,
        uint16 _findersFeeBps
    ) external;

    /// @notice Updates the ask price for a given NFT
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The ID of the ERC-721 token
    /// @param _askPrice The ask price to set
    /// @param _askCurrency The address of the ERC-20 token required to fill, or address(0) for ETH
    function setAskPrice(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _askPrice,
        address _askCurrency
    ) external;

    /// @notice Cancels the ask for a given NFT
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The ID of the ERC-721 token
    function cancelAsk(address _tokenContract, uint256 _tokenId) external;

    /// @notice Fills the ask for a given NFT, transferring the ETH/ERC-20 to the seller and NFT to the buyer
    /// @param _tokenContract The address of the ERC-721 token
    /// @param _tokenId The ID of the ERC-721 token
    /// @param _fillCurrency The address of the ERC-20 token using to fill, or address(0) for ETH
    /// @param _fillAmount The amount to fill the ask
    /// @param _finder The address of the ask referrer
    function fillAsk(
        address _tokenContract,
        uint256 _tokenId,
        address _fillCurrency,
        uint256 _fillAmount,
        address _finder
    ) external;
}