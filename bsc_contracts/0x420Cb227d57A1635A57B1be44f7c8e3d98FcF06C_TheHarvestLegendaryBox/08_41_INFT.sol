// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface INFT {
    function mint(address to) external returns (uint256 tokenId);

    function burn(uint256 tokenId) external;

    function setBaseTokenURI(string calldata baseTokenURI) external;

    function setTokenURI(uint256 tokenId, string calldata _tokenURI) external;

    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
}

interface INFTUpgradeable is IERC721Upgradeable, INFT {}