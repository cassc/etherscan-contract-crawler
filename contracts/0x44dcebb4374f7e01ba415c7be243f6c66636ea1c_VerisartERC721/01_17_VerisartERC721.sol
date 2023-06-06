// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../royalties/Royalties.sol";
import "../Signable.sol";

// Version: Verisart-1.1
contract VerisartERC721 is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Ownable,
    Royalties
{
    string private _baseURIextended;

    // OpenSea metadata freeze
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory baseURI) ERC721("Verisart", "VER") {
        _baseURIextended = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }

    function mint(
        address to,
        uint256 tokenId,
        string memory _tokenURI,
        address payable receiver,
        uint256 basisPoints,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public validRoyalties(basisPoints) {
        require(
            owner() == Signable.recoverAddress(tokenId, _tokenURI, v, r, s),
            "Valid signature required"
        );
        require(msg.sender == to, "Can only mint to msg.sender");

        _mintSingle(to, tokenId, _tokenURI, receiver, basisPoints);
    }

    function mintBulk(
        address to,
        uint256 tokenId,
        string[] memory _tokenURIs,
        address payable receiver,
        uint256 basisPoints,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public validRoyalties(basisPoints) {
        require(
            owner() ==
                Signable.recoverAddressBulk(tokenId, _tokenURIs, v, r, s),
            "Valid signature required"
        );

        require(msg.sender == to, "Can only mint to msg.sender");

        _mintBulk(to, tokenId, _tokenURIs, receiver, basisPoints);
    }

    /**
     * @dev Verisart mints on behalf of users who have given permission
     */
    function mintVerisart(
        address _to,
        uint256 tokenId,
        string memory _tokenURI,
        address payable receiver,
        uint256 basisPoints,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyOwner validRoyalties(basisPoints) {
        address to = Signable.recoverPersonalAddress(tokenId, _tokenURI, v, r, s);

        require(to == _to, "Signature wrong for expected `to`");

        _mintSingle(to, tokenId, _tokenURI, receiver, basisPoints);
    }

    /**
     * @dev Verisart bulk mints on behalf of users who have given permission
     */
    function mintBulkVerisart(
        address _to,
        uint256 tokenId,
        string[] memory _tokenURIs,
        address payable receiver,
        uint256 basisPoints,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyOwner validRoyalties(basisPoints) {
        address to = Signable.recoverPersonalAddressBulk(
            tokenId,
            _tokenURIs,
            v,
            r,
            s
        );

        require(to == _to, "Signature wrong for expected `to`");

        _mintBulk(to, tokenId, _tokenURIs, receiver, basisPoints);
    }

    /**
     * @dev Royalties are set naively on minting so this check
     * is performed once before minting to avoid extra unnecessary gas
     */
    modifier validRoyalties(uint256 basisPoints) {
        require(basisPoints < 10001, "Total royalties exceeds 100%");
        _;
    }

    function _mintBulk(
        address to,
        uint256 baseTokenId,
        string[] memory _tokenURIs,
        address payable receiver,
        uint256 basisPoints
    ) internal {
        for (uint256 i = 0; i < _tokenURIs.length; i++) {
            _mintSingle(to, baseTokenId + i, _tokenURIs[i], receiver, basisPoints);
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