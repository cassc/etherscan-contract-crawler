// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface ICollectionProxy {
    /**
     * @dev IERC165
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /**
     * @dev IERC721
     */
    function balanceOf(address user) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev IERC721Metadata
     */
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function baseURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @dev IERC721Enumerable
     */
    function totalSupply() external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev safeMint function
     */
    function safeMint(address to, uint256 quantity, bool payWithWETH) external payable;

    /**
     * @dev IERC721Burnable
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev IERC721Ownable
     */
    function owner() external view returns (address);

    /**
     * @dev IERC2981
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address, uint256);
}