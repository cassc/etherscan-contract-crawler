// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPositionMetadata.sol";
import "../interfaces/IPosition.sol";
contract Position is ERC721, ERC721Enumerable, Ownable, IPosition {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    IPositionMetadata public metadata;
    constructor(IPositionMetadata _metadata) ERC721("Maverick Position NFT", "MPN") {
        metadata = _metadata;
        _tokenIdCounter.increment();
    }
    function setMetadata(IPositionMetadata _metadata) external onlyOwner {
        metadata = _metadata;
        emit SetMetadata(metadata);
    }
    function mint(address to) external returns (uint256 tokenId) {
        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Invalid Token ID");
        return metadata.tokenURI(tokenId);
    }
    function tokenOfOwnerByIndexExists(address ownerToCheck, uint256 index) external view returns (bool) {
        return index < balanceOf(ownerToCheck);
    }
}