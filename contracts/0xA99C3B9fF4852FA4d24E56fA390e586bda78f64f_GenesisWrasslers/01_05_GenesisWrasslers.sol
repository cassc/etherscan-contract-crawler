// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GenesisWrasslers is ERC721, Ownable {
    using Strings for uint256;
    uint256 public nextTokenId = 1;
    string public baseUri;
    string public pfpUri;

    mapping(uint256 => uint8) public renderers;

    constructor() ERC721("Genesis Wrasslers", "GENWRASS") {}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (renderers[tokenId] == 1) {
            return string(abi.encodePacked(pfpUri, tokenId.toString()));
        }

        return string(abi.encodePacked(baseUri, tokenId.toString()));
    }

    function mintToRecipient(address recipient) external onlyOwner {
        require(nextTokenId < 13, "Max 12 Genesis Wrasslers");
        _mint(recipient, nextTokenId);
        unchecked {
            ++nextTokenId;
        }
    }

    function setURIs(string calldata _baseUri, string calldata _pfpUri) external onlyOwner {
        baseUri = _baseUri;
        pfpUri = _pfpUri;
    }

    function setRenderer(uint256 tokenId, uint8 renderCode) external {
        require(ownerOf(tokenId) == msg.sender, "Only owner can set renderer.");
        renderers[tokenId] = renderCode;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        require(tokenId > 0, "ERC721: owner query for nonexistent token");
        return tokenId < nextTokenId;
    }
}