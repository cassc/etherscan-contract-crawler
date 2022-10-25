// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IOuterRingNFT is IERC721Upgradeable {
    function getFirstOwner(uint256 tokenId) external view returns (address);
}