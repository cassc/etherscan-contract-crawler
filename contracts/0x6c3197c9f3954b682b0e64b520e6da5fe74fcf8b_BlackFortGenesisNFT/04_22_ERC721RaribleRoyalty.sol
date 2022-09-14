// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "./ERC2981Rarible.sol";


abstract contract ERC721RaribleRoyalty is ERC721Royalty, ERC2981Rarible {

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Royalty, ERC2981Rarible) returns (bool) {
        return ERC721Royalty.supportsInterface(interfaceId) || ERC2981Rarible.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) public override(ERC2981Rarible, ERC2981) view returns (address, uint256) {
        return super.royaltyInfo(tokenId, salePrice);
    }
}