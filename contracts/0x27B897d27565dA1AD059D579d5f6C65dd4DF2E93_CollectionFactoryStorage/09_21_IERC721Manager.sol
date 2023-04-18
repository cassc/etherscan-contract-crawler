// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IERC721Manager {
    /**
     * @dev IERC165
     */
    function supportsInterface(bytes4) external view returns (bool);

    /**
     * @dev IERC721
     */
    function balanceOf(address collectionProxy, address owner) external view returns (uint256);

    function ownerOf(address collectionProxy, uint256 tokenId) external view returns (address);

    function safeTransferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    function transferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(
        address collectionProxy,
        address msgSender,
        address spender,
        uint256 tokenId
    ) external;

    function getApproved(address collectionProxy, uint256 tokenId) external view returns (address);

    function setApprovalForAll(
        address collectionProxy,
        address owner,
        address operator,
        bool approved
    ) external;

    function isApprovedForAll(
        address collectionProxy,
        address owner,
        address operator
    ) external view returns (bool);

    /**
     * @dev IERC721Metadata
     */
    function name(address collectionProxy) external view returns (string memory);

    function symbol(address collectionProxy) external view returns (string memory);

    function baseURI(address collectionProxy) external view returns (string memory);

    function tokenURI(
        address collectionProxy,
        uint256 tokenId
    ) external view returns (string memory);

    /**
     * @dev IERC721Enumerable
     */
    function totalSupply(address collectionProxy) external view returns (uint256);

    function tokenByIndex(
        address collectionProxy,
        uint256 index
    ) external view returns (uint256 tokenId);

    function tokenOfOwnerByIndex(
        address collectionProxy,
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    /**
     * @dev IERC721Burnable
     */
    function burn(address collectionProxy, address burner, uint256 tokenId) external;

    /**
     * @dev IERC721Ownable
     */
    function owner() external view returns (address);

    /**
     * @dev IERC2981
     */
    function royaltyInfo(
        address collectionProxy,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address, uint256);
}