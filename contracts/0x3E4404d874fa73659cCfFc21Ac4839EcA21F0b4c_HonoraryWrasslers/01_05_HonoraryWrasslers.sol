// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HonoraryWrasslers is ERC721, Ownable {
    using Strings for uint256;
    uint256 public nextTokenId = 1;
    string public baseUri;

    constructor() ERC721("Honorary Wrasslers", "HWRASS") {}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseUri, tokenId.toString()));
    }

    function mintToRecipient(address recipient) external onlyOwner {
        _mint(recipient, nextTokenId);
        unchecked {
            ++nextTokenId;
        }
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseUri = _uri;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        require(tokenId > 0, "ERC721: owner query for nonexistent token");
        return tokenId < nextTokenId;
    }
}