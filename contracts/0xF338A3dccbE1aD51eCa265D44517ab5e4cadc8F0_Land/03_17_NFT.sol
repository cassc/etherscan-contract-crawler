// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

abstract contract NFT is ERC721Upgradeable {
    uint256 constant clearLow =
        0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
    uint256 constant clearHigh =
        0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    uint256 constant factor = 0x100000000000000000000000000000000;

    mapping(uint256 => string) tokenMetadataCID;

    modifier isNFTOwner(uint256 _tokenId) {
        require(msg.sender == ownerOf(_tokenId), "You are not nft owner");
        _;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return tokenMetadataCID[tokenId];
    }

    function _mintNFT(address _to, uint256 _tokenID) internal {
        _safeMint(_to, _tokenID);
    }

    function burn(uint256 _tokenId) internal isNFTOwner(_tokenId) {
        _burn(_tokenId);
    }

    function _updateURI(uint256 _tokenId, string memory _uri) internal {
        tokenMetadataCID[_tokenId] = _uri;
    }
}