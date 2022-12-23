// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract NFTToken721 is ERC721URIStorage, ERC2981, ERC721Burnable {
    address marketPlaceAddress;

    constructor(address _marketplaceAddress) ERC721("PurrNFT", "PNFT") {
        marketPlaceAddress = _marketplaceAddress;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function createToken(
        uint256 tokenID,
        string memory uri,
        uint96 royaltyFraction,
        address receiver
    ) public {
        _mint(msg.sender, tokenID);
        _setTokenURI(tokenID, uri);
        setApprovalForAll(marketPlaceAddress, true);
        if (royaltyFraction > 0)
            _setTokenRoyalty(tokenID, receiver, royaltyFraction);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}