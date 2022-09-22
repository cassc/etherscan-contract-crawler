// contracts/IPaperCompatibleInterface1155.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPaperCompatibleInterface1155 {
    /// @custom:required
    ///
    /// @notice Gets any potential reason that the _userWallet is not able to claim _quantity of NFT.
    ///
    /// @dev You do not need to check if the user has enough balance in their wallet
    /// @dev You also do not need to check if there is enough quantity left to be claimed
    ///
    /// @param _userWallet The address of the user's wallet
    /// @param _quantity The number of NFTs to be purchased
    /// @param _tokenId The id of the NFT that the ineligibility reason corrsponds too.
    ///
    /// @return string containing the reason that they _userWallet cannot claim _quantity of the NFT if any. Empty string if the _userWallet can claim _quantity of the NFT.
    function getClaimIneligibilityReason(
        address _userWallet,
        uint256 _quantity,
        uint256 _tokenId
    ) external view returns (string memory);

    /// @custom:required
    ///
    /// @notice Checks the total amount of NFTs left to be claimed
    ///
    ///
    /// @param _tokenId The id of the NFT that the unclaimed supply corrsponds too.
    ///
    /// @return uint256 The number of NFTs left to be claimed
    function unclaimedSupply(uint256 _tokenId) external view returns (uint256);

    /// @custom:required
    ///
    /// @notice Checks the price of the NFT
    ///
    /// @param _tokenId The id of the NFT which the pricing corresponds too.
    ///
    /// @return uint256 The price of a single NFT in Wei
    function price(uint256 _tokenId) external view returns (uint256);

    /// @custom:required
    ///
    /// @notice Used by paper to purchase and deliver the NFT to the user.
    ///
    /// @dev This function should emit event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId)
    ///
    /// @param _userWallet The address of the user's wallet
    /// @param _quantity The number of NFTs to be purchased
    /// @param _tokenId The id of the NFT to be purchased
    function claimTo(
        address _userWallet,
        uint256 _quantity,
        uint256 _tokenId
    ) external payable;
}