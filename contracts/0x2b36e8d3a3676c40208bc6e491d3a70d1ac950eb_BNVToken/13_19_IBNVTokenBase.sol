// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title BNV Token Base Interface 
/// @author Sensible Lab
/// @dev based on a standard ERC721
interface IBNVTokenBase is IERC721 {

    /// @notice Emitted when royalty `amount` is paid `tokenId` by `payee`
    event RoyaltyPaid(uint256 indexed tokenId, address indexed payee, uint256 amount);

    /// @notice Emitted when royalty `amount` is distributed to beneficiaries of `tokenId`
    event RoyaltyDistributed(uint256 indexed tokenId, address indexed to, uint256 amount);

    function setLastSoldPrice(uint256 tokenId, uint256 lastSoldPrice) external;

    function mint(address to, uint256 tokenId, uint256 dropId, string memory uri, uint lastSoldPrice) external;

    function transferWithRoyalty(address to, uint256 tokenId) external payable;

    function payRoyalty(uint256 tokenId) external payable;

    // VIEW ONLY =======================================

    function royaltyPayableOf(uint256 tokenId) external view returns (uint256);

    function royaltyRateOf(uint256 dropId) external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);
    
    function dropOf(uint256 tokenId) external view returns (uint256);

    function beneficiariesOf(uint256 dropId) external view returns (address[] memory);

    function beneficiarySplitsOf(uint256 dropId) external view returns (uint256[] memory);

    function lastSoldPriceOf(uint256 tokenId) external view returns (uint256);

    function getTokenLock(uint256 tokenId) external view returns (uint256);

}