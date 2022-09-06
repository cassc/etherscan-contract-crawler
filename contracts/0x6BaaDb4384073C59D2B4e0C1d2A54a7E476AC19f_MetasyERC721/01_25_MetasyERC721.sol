// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";


contract MetasyERC721 is ERC721, ERC721Enumerable, ERC721URIStorage, EIP712, ERC721Votes, ERC2981, Ownable {
    string private __baseURI;

    event BatchMinted(uint256 startId, uint256 endId);

    constructor(string memory _name, string memory _symbol, string memory baseURI_)
    ERC721(_name, _symbol)
    EIP712("Metasy", "1")
    {
        __baseURI = baseURI_;
    }


    function mint(uint256 newItemId, string memory tokenURI_)
    public
    virtual
    onlyOwner
    returns (uint256)
    {
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI_);

        return newItemId;
    }

    function mintTo(uint256 newItemId, string memory tokenURI_, address to)
    public
    virtual
    onlyOwner
    returns (uint256)
    {
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, tokenURI_);

        return newItemId;
    }

    function batchMintTo(uint256 startId, string[] memory tokenURIs_, address to)
    public
    virtual
    onlyOwner
    {
        for (uint256 i = 0; i < tokenURIs_.length; i++) {
            mintTo(startId + i, tokenURIs_[i], to);
        }

        emit BatchMinted(startId, startId + tokenURIs_.length - 1);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        __baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setDefaultRoyalty(address to_, uint96 defaultRoyalty_) external onlyOwner {
        _setDefaultRoyalty(to_, defaultRoyalty_);
    }

    function setRoyaltyForToken(uint256 tokenId, address to_, uint96 royalty) external onlyOwner {
        _setTokenRoyalty(tokenId, to_, royalty);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


    function burn(uint256 tokenId) public onlyOwner() {
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }


    function ownerOf(uint256 tokenId) public view override(ERC721, IERC721) returns (address){
        require(_exists(tokenId), "Token does not exist");
        return super.ownerOf(tokenId);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Votes, ERC721) {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}