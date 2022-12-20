// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./IBitHotelCollection.sol";
import "./ERC2981PerTokenRoyalties.sol";

contract BitHotelCollection is
    IBitHotelCollection,
    AccessControl,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC2981PerTokenRoyalties
{
    using Counters for Counters.Counter;

    struct Collection {
        bool locked;
    }

    mapping(uint256 => Collection) private _collections;
    mapping(uint256 => address[]) private _ownersHistory;

    address[] private _owners;
    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    string private _baseTokenURI;
    string private _uri;
    address private _controller;
    uint256 private _replicas;

    Counters.Counter private _tokenId;

    modifier onlyController(address controller_) {
        // solhint-disable-next-line reason-string
        require(controller() == controller_, "BitHotelCollection: not a controller address.");
        _;
    }

    modifier notLocked(uint256 tokenId) {
        if (_collections[tokenId].locked) {
            revert TokenLocked(tokenId);
        }
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory uri_,
        address controller_,
        uint256 replicas_
    ) ERC721(name, symbol) {
        _controller = controller_;
        _replicas = replicas_;
        _uri = uri_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev See {IBitHotelCollection-tokenIds}.
     */
    function tokenIds() external view returns (uint256[] memory) {
        return _allTokens;
    }

    /**
     * @dev See {IBitHotelCollection-ownersHistory}.
     */
    function ownersHistory(uint256 tokenId) external view returns (address[] memory) {
        return _ownersHistory[tokenId];
    }

    /**
     * @dev See {IBitHotelCollection-locked}.
     */
    function locked(uint256 tokenId) external view returns (bool) {
        return _collections[tokenId].locked;
    }

    /**
     * @dev See {IBitHotelCollection-setRoomInfos}.
     */
    function setCollectionInfos(uint256 tokenId, bool locked_) external onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        require(tokenId != 0, "BitHotelCollection: tokenId is the zero value");
        Collection storage collection = _collections[tokenId];
        collection.locked = locked_;
    }

    /**
     * @dev See {IBitHotelCollection-setController}.
     */
    function setController(address controller_) external onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        require(controller_ != address(0), "BitHotelCollection: controller is the zero address");
        // solhint-disable-next-line reason-string
        require(controller_ != controller(), "BitHotelCollection: controller already updated");
        _controller = controller_;
        emit ControllerChanged(controller_);
    }

    /**
     * @dev See {IBitHotelCollection-lockTokenId}.
     */
    function lockTokenId(uint256 tokenId) external onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        require(_exists(tokenId), "BitHotelCollection: change for nonexistent token");
        _collections[tokenId].locked = true;
        emit TokenIdLocked(tokenId, true);
    }

    /**
     * @dev See {IBitHotelCollection-releaseLockedTokenId}.
     */
    function releaseLockedTokenId(uint256 tokenId) external onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        require(_exists(tokenId), "BitHotelCollection: change for nonexistent token");
        // solhint-disable-next-line reason-string
        require(_collections[tokenId].locked == true, "BitHotelCollection: tokenId not locked");
        _collections[tokenId].locked = false;
        emit TokenIdReleased(tokenId, false);
    }

    /**
     * @dev See {IBitHotelCollection-controller}.
     */
    function controller() public view returns (address) {
        return _controller;
    }

    /**
     * @dev See {IBitHotelCollection-replicas}.
     */
    function replicas() public view returns (uint256) {
        return _replicas;
    }

    /**
     * @dev See {IBitHotelCollection-uri}.
     */
    function uri() public view returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IBitHotelCollection-baseURI}.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev See {IBitHotelCollection-exists}.
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721, ERC721Enumerable, ERC165, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IBitHotelCollection.setBaseURI}.
     */
    function setBaseURI(string memory newBaseTokenURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        string memory oldBaseTokenURI = baseURI();
        _baseTokenURI = newBaseTokenURI;
        emit BaseUriChanged(oldBaseTokenURI, newBaseTokenURI);
    }

    /**
     * @dev See {IBitHotelCollection.setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string memory tokenURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(_exists(tokenId), "BitHotelCollection: change uri for nonexistent token");
        _setTokenURI(tokenId, tokenURI_);
    }

    /**
     * @dev See {IBitHotelCollection-mint}.
     * WARNING: Usage of this method is discouraged, use {safeMint} whenever possible
     */
    function mint(
        address to,
        address royaltyRecipient,
        uint256 royaltyValue
    ) public onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        _tokenId.increment();

        uint256 tokenId = _tokenId.current();

        require(tokenId <= replicas(), "BitHotelCollection: all tokens already minted.");

        _mint(to, tokenId);
        _setTokenURI(tokenId, _uri);

        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
        }

        _allTokens.push(tokenId);

        emit TokenMint(tokenId, to);
    }

    function bulkSafeMint(
        address[] calldata tos,
        address royaltyRecipient,
        uint256 royaltyValue,
        bytes memory data_
    ) public onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        require(tos.length > 0, "BitHotelCollection: empty tos");
        // solhint-disable-next-line reason-string
        for (uint256 i = 0; i < tos.length; i++) {
            safeMint(tos[i], royaltyRecipient, royaltyValue, data_);
        }
    }

    /**
     * @dev See {IBitHotelCollection-safeMint}.
     */
    function safeMint(
        address to,
        address royaltyRecipient,
        uint256 royaltyValue,
        bytes memory data_
    ) public onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        _tokenId.increment();

        uint256 tokenId = _tokenId.current();

        require(tokenId <= replicas(), "BitHotelCollection: all tokens already minted.");

        super._safeMint(to, tokenId, data_);
        _setTokenURI(tokenId, _uri);
        // _tokenId.increment();

        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
        }

        _allTokens.push(tokenId);
        emit TokenMint(tokenId, to);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) notLocked(tokenId) {
        super._beforeTokenTransfer(from, to, tokenId);
        // add owner to _ownersHistory
        _ownersHistory[tokenId].push(to);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) onlyRole(DEFAULT_ADMIN_ROLE) {
        super._burn(tokenId);
    }
}