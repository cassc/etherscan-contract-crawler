// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/IKOLOMusic.sol";
import "./base/AccessControlBase.sol";

contract KOLOMusic is IKOLOMusic, ERC721, AccessControlBase {

    using SafeMath for uint256;

    mapping(uint256 => MusicContent) public nft2Content;

    uint256 public totalSupply = 0;

    string public baseURI;

    event SafeMintMusic(address to, uint256 tokenId, MusicContent content, uint64 time);

    constructor(string memory _baseURI) ERC721("KOLO Music", "KLM") {
        baseURI = _baseURI;
    }

    function safeMintMusic(address to, uint256 tokenId, MusicContent memory content) public override onlyMinter {

        require(!_exists(tokenId), "Already exists");

        _safeMint(to, tokenId);
        nft2Content[tokenId] = content;
        totalSupply = totalSupply.add(1);

        emit SafeMintMusic(to, tokenId, content, uint64(block.timestamp));
    }

    function getMusicContent(uint256 tokenId) external view override returns(MusicContent memory) {
        return nft2Content[tokenId];
    }

    function burnMusic(uint256 tokenId) public override onlyMinter{
        _burn(tokenId);
        totalSupply = totalSupply.sub(1);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function setBaseURI(string memory baseURI_) external onlyAdmin {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721,AccessControlBase) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}