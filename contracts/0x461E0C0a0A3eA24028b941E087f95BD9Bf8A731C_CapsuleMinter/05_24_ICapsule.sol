// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../openzeppelin/contracts/interfaces/IERC2981.sol";

interface ICapsule is IERC721, IERC2981 {
    function mint(address account, string memory _uri) external;

    function burn(address owner, uint256 tokenId) external;

    function setMetadataProvider(address _metadataAddress) external;

    // Read functions
    function baseURI() external view returns (string memory);

    function counter() external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);

    function isCollectionPrivate() external view returns (bool);

    function isCollectionMinter(address _account) external view returns (bool);

    function maxId() external view returns (uint256);

    function royaltyRate() external view returns (uint256);

    function royaltyReceiver() external view returns (address);

    function tokenURIOwner() external view returns (address);

    // Admin functions
    function lockCollectionCount(uint256 _nftCount) external;

    function setBaseURI(string calldata baseURI_) external;

    function setTokenURI(uint256 _tokenId, string memory _newTokenURI) external;

    function updateTokenURIOwner(address _newTokenURIOwner) external;

    function updateRoyaltyConfig(address _royaltyReceiver, uint256 _royaltyRate) external;
}