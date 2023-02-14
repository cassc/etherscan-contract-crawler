// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint,uint)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty is owed and to whom.
    /// @param id - the NFT asset queried for royalty information
    /// @param salePrice - the sale price of the NFT asset specified by id
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for salePrice
    function royaltyInfo(uint id, uint salePrice) external view returns (address receiver, uint royaltyAmount);
}