// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

/*         __                __      __
     _____/ /_____  _____   / /___ _/ /_
    / ___/ __/ __ \/ ___/  / / __ `/ __ \
   / /__/ /_/ /_/ / /     / / /_/ / /_/ /
   \___/\__/\____/_/     /_/\__,_/_.___/

                               ctor.xyz   */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PF2T is ERC721, ERC721URIStorage, ERC721Royalty, Ownable {
    string private _baseTokenURI =
        "ipfs://QmXZLUdyYv7ud2yqJCdwW7RBMbcbMBmcz8pFdqmWhPtfCe/";

    event PermanentURI(string uri, uint256 indexed tokenId);

    constructor() ERC721("Post Futurism II - TAMASHII", "PF2T") {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Royalty)
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

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string calldata baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setTokenURI(uint256 tokenId, string calldata _tokenURI)
        external
        onlyOwner
    {
        _setTokenURI(tokenId, _tokenURI);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    function freezeMetadata(uint256 tokenId) external onlyOwner {
        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage, ERC721Royalty)
    {
        super._burn(tokenId);
    }
}