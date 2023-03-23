// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface ICallToken {
    function factory() external returns(address);
    function nft() external returns(address);

    event Mint(address indexed user, uint256 indexed tokenId);

    function mint(address user, uint256 tokenId) external;

    event Burn(address indexed user, uint256 indexed tokenId);

    function burn(uint256 tokenId) external;

    function open(address user, uint256 tokenId) external;

    event BaseURIUpdated(string newBaseURI);

    function updateBaseURI(string memory baseURI) external;

    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.    
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}