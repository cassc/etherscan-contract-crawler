// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../royalties/Royalties.sol";

contract DerekBoshier is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Ownable,
    Royalties
{
    // OpenSea metadata freeze
    event PermanentURI(string _value, uint256 indexed _id);

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _editionCounter;
    string private _baseURIextended;
    uint256 private _MAX_singles = 1000000;

    constructor(
        string memory baseURI,
        string memory contractName,
        string memory tokenSymbol
    ) ERC721(contractName, tokenSymbol) {
        _baseURIextended = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }

    /*
     * @dev hard limit of _MAX_singles single tokens
     */
    function mint(
        address to,
        string memory _tokenURI,
        address payable receiver,
        uint256 basisPoints
    ) public onlyOwner {
        require(basisPoints < 10000, "Total royalties exceeds 100%");
        uint256 tokenId = getNextTokenId();
        require(
            tokenId < _MAX_singles,
            "Maximum number of single tokens exceeded"
        );

        _mintSingle(to, tokenId, _tokenURI, receiver, basisPoints);
        _tokenIdCounter.increment();
    }

    function mintEditions(
        address to,
        string memory _tokenURI,
        uint256 count,
        address payable receiver,
        uint256 basisPoints
    ) public onlyOwner {
        require(basisPoints < 10000, "Total royalties exceeds 100%");
        require(count < 101, "Max of 100 tokens per edition");
        require(count > 1, "Must be more than 1 token per edition");

        uint256 tokenId = getNextEditionId();
        _mintEditions(to, tokenId, count, _tokenURI, receiver, basisPoints);
        _editionCounter.increment();
    }

    function getNextTokenId() public view returns (uint256) {
        return _tokenIdCounter.current() + 1;
    }

    function getNextEditionId() public view returns (uint256) {
        return ((_editionCounter.current() + 1) * _MAX_singles) + 1;
    }

    function _mintEditions(
        address to,
        uint256 tokenId,
        uint256 count,
        string memory _tokenURI,
        address payable receiver,
        uint256 basisPoints
    ) internal {
        for (uint256 i = 0; i < count; i++) {
            _mintSingle(to, tokenId + i, _tokenURI, receiver, basisPoints);
        }
    }

    function _mintSingle(
        address to,
        uint256 tokenId,
        string memory _tokenURI,
        address payable receiver,
        uint256 basisPoints
    ) internal {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        if (basisPoints > 0) {
            _setRoyalties(tokenId, receiver, basisPoints);
        }
        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _existsRoyalties(uint256 tokenId)
        internal
        view
        virtual
        override(Royalties)
        returns (bool)
    {
        return super._exists(tokenId);
    }

    function _getRoyaltyFallback()
        internal
        view
        override
        returns (address payable)
    {
        return payable(owner());
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            _supportsRoyaltyInterfaces(interfaceId);
    }
}