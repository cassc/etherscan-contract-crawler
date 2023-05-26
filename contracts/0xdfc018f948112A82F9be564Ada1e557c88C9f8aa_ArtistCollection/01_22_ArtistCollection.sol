// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../royalties/Royalties.sol";
import "../Signable.sol";

// Version: Artist-4.0
contract ArtistCollection is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Royalties,
    AccessControlEnumerable
{
    // OpenSea metadata freeze
    event PermanentURI(string _value, uint256 indexed _id);

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _editionCounter;
    string private _baseURIextended;
    uint256 private constant _MAX_SINGLES = 100000000;

    /*
        * @dev allows the artist (and potentially other 3rd parties) permission to mint
        * on behalf of the artist
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Allows minting via signable mint (an off-chain signature from a `MINTER_ROLE` user is still required)
     */
    bool private _signableMinting = false;

    function getSignableMinting() public view returns (bool){
        return _signableMinting;
    }

    function setSignableMinting(bool val) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "This action can only be performed by an admin");
        _signableMinting = val;
    }

    constructor(
        string memory baseURI,
        string memory contractName,
        string memory tokenSymbol,
        address artist
    ) ERC721(contractName, tokenSymbol) {
        _baseURIextended = baseURI;

        /**
        * @dev Minter admin is set as the artist meaning they have rights over the minter role
        * Singable minter is used to provide gassless minting and can be revoked by the default admin (i.e. artist)
        * The minter admin role can be updated by the default admin only
        */
        _setupRole(DEFAULT_ADMIN_ROLE, artist);
        _setupRole(MINTER_ROLE, artist);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * Required to allow the artist to administrate the contract on OpenSea.
     * Note if there are many addresses with the DEFAULT_ADMIN_ROLE, the one which is returned may be arbitrary.
     */
    function owner() public view virtual returns (address) {
        return _getPrimaryAdmin();
    }

    function _getPrimaryAdmin() internal view virtual returns (address) {
        if (getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 0) {
            return address(0);
        }
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /**
     * @dev Throws if called by any account other than an approved minter.
     */
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Restricted to approved minters");
        _;
    }

    function mintAndTransfer(
        address to,
        string memory _tokenURI,
        address payable receiver,
        uint256 basisPoints
    ) public onlyMinter {
        uint256 newestToken = getNextTokenId();
        mint(msg.sender, _tokenURI, receiver, basisPoints);
        safeTransferFrom(msg.sender, to, newestToken);
    }

    /*
     * @dev hard limit of _MAX_SINGLES single tokens
     */
    function mint(
        address to,
        string memory _tokenURI,
        address payable receiver,
        uint256 basisPoints
    ) public onlyMinter {
        require(basisPoints < 10001, "Total royalties exceeds 100%");
        uint256 tokenId = getNextTokenId();
        require(
            tokenId < _MAX_SINGLES,
            "Maximum number of single tokens exceeded"
        );

        _mintSingle(to, tokenId, _tokenURI, receiver, basisPoints);
        _tokenIdCounter.increment();
    }

    function mintEditions(
        address to,
        string[] memory _tokenURIs,
        address payable receiver,
        uint256 basisPoints
    ) public onlyMinter {
        require(basisPoints < 10001, "Total royalties exceeds 100%");
        require(_tokenURIs.length > 1, "Must be more than 1 token per edition");

        uint256 tokenId = getNextEditionId();
        _mintEditions(to, tokenId, _tokenURIs, receiver, basisPoints);
        _editionCounter.increment();
    }

    /**
     * @dev Allows a third party to mint on artists behalf but only when the artist provides an off-chain
     * signature each time.
     *
     * Note signer needs to peek at expected next token ID using getNextTokenId() and include this in their
     * signature. This is required to avoid replay attacks.
     */
    function mintSignable(
        address to,
        string memory _tokenURI,
        address payable receiver,
        uint256 basisPoints,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(_signableMinting == true, "Global signable minting must be turned on");
        require(basisPoints < 10001, "Total royalties exceeds 100%");
        uint256 tokenId = getNextTokenId();
        require(
            tokenId < _MAX_SINGLES,
            "Maximum number of single tokens exceeded"
        );

        address authorizer = Signable.recoverPersonalAddress(tokenId, _tokenURI, v, r, s);
        
        require(hasRole(MINTER_ROLE, authorizer), "Signature wrong.");

        _mintSingle(to, tokenId, _tokenURI, receiver, basisPoints);
        _tokenIdCounter.increment();
    }

    /**
     * As mintSignable except for editions
     *
     * Note signer needs to peek at expected next token ID using getNextEditionId() and include this in their
     * signature. This is required to avoid replay attacks.
     */
    function mintEditionsSignable(
        address to,
        string[] memory _tokenURIs,
        address payable receiver,
        uint256 basisPoints,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(_signableMinting == true, "Global signable minting must be turned on");
        require(basisPoints < 10001, "Total royalties exceeds 100%");
        require(_tokenURIs.length > 1, "Must be more than 1 token per edition");
        uint256 tokenId = getNextEditionId();
        address authorizer = Signable.recoverPersonalAddressBulk(
            tokenId,
            _tokenURIs,
            v,
            r,
            s
        );
        require(hasRole(MINTER_ROLE, authorizer), "Signature wrong.");

        _mintEditions(to, tokenId, _tokenURIs, receiver, basisPoints);
        _editionCounter.increment();
    }

    function _mintEditions(
        address to,
        uint256 tokenId,
        string[] memory _tokenURIs,
        address payable receiver,
        uint256 basisPoints
    ) internal {
        for (uint256 i = 0; i < _tokenURIs.length; i++) {
            _mintSingle(to, tokenId + i, _tokenURIs[i], receiver, basisPoints);
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

    function getNextTokenId() public view returns (uint256) {
        return _tokenIdCounter.current() + 1;
    }

    function getNextEditionId() public view returns (uint256) {
        return ((_editionCounter.current() + 1) * _MAX_SINGLES) + 1;
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
        return payable(_getPrimaryAdmin());
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            _supportsRoyaltyInterfaces(interfaceId);
    }
}