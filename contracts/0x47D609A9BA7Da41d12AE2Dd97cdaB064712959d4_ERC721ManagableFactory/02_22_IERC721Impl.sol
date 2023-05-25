// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IERC721Impl is IERC721, IERC721Metadata {

    event BaseUriSet(string newBaseUri);
    event TokenUriSet(uint256 indexed tokenId, string uri);
    event ReservedUrisChanged();

    function owner() external view returns (address);

    function mintTo(address minter) external;

    function mintTo(address minter, string memory uri) external;

    function mintTo(address minter, uint256 amount) external;

    function mintTo(address minter, uint256 amount, string[] memory uris) external;

    function canMint(uint256 amount) external view returns (bool);

    function burn(uint256 tokenId) external;

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

    function getTokenURI(uint256 tokenId) external view returns (string memory);

    function totalMinted() external view returns (uint256);

    function totalBurned() external view returns (uint256);
}