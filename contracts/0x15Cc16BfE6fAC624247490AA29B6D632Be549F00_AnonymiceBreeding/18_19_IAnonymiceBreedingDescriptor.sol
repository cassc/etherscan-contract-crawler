// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IAnonymiceBreedingDescriptor is IERC721Enumerable {
    function tokenIdToMetadata(uint256 _tokenId)
        external
        view
        returns (string memory);

    function tokenIdToSVG(uint256 _tokenId)
        external
        view
        returns (string memory);

    function tokenURI(uint256 _tokenId)
        external
        view
        returns (string memory);
}