// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SHiFTTeam is ERC721, Ownable {
    uint256 counter;
    mapping(uint256 => string) private _tokenURIs;

    event MetadataUpdate(uint256 _tokenId);

    constructor() ERC721("SHiFT team", "SHiFT") {}

    function mint(string[] calldata tokenUris) external onlyOwner {
        for (uint256 i = 0; i < tokenUris.length; i = inc(i)) {
            uint256 tokenId = counter++;
            _safeMint(owner(), tokenId);
            _tokenURIs[tokenId] = tokenUris[i];
        }
    }

    function burn(uint256[] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i = inc(i)) {
            _burn(ids[i]);
        }
    }

    function changeTokenUri(
        uint256 tokenId,
        string calldata tokenUriNew
    ) external onlyOwner {
        _tokenURIs[tokenId] = tokenUriNew;
        emit MetadataUpdate(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return _tokenURIs[tokenId];
    }

    function inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }
}