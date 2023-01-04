// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";



contract UniDAOSharesERC721 is ERC721, ERC721URIStorage, EIP712, ERC721Votes, ERC2981, Ownable {
    string private __baseURI;
    uint256 constant HARD_CAP = 69;

    mapping(uint256=>bool) minted;


    constructor(string memory _name, string memory _symbol, string memory baseURI_)
    ERC721(_name, _symbol)
    EIP712("UniDAO", "1")
    {
        __baseURI = baseURI_;
    }


    function mintTo(uint256 tokenId_, string memory tokenURI_, address to)
    public
    virtual
    onlyOwner
    {
        require(tokenId_ <= HARD_CAP && tokenId_ > 0);
        require(!minted[tokenId_]);

        _mint(to, tokenId_);
        _setTokenURI(tokenId_, tokenURI_);

        minted[tokenId_] = true;
    }

    function batchMintTo(uint256[] memory tokenIds_, string[] memory tokenURIs_, address to)
    public
    virtual
    onlyOwner
    {
        require(HARD_CAP>=(tokenIds_.length));
        require(tokenIds_.length == tokenURIs_.length);

        for (uint256 i = 0; i < tokenURIs_.length; i++) {
            mintTo(tokenIds_[i], tokenURIs_[i], to);
        }
    }

    function batchTransfer(uint256[] calldata ids, address to) public {
        for(uint i=0; i<ids.length; i++){
            safeTransferFrom(msg.sender, to, ids[i]);
        }
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
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
        minted[tokenId] = false;
        super._burn(tokenId);
    }


    function setDefaultRoyalty(address to_, uint96 defaultRoyalty_) external onlyOwner {
        _setDefaultRoyalty(to_, defaultRoyalty_);
    }

    function setRoyaltyForToken(uint256 tokenId, address to_, uint96 royalty) external onlyOwner {
        _setTokenRoyalty(tokenId, to_, royalty);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Votes, ERC721) {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}