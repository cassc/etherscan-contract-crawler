// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./IBitHotelRoomCollection.sol";
import "./ERC2981PerTokenRoyalties.sol";

contract BitHotelRoomCollection is IBitHotelRoomCollection, AccessControl, ERC721Enumerable, ERC721URIStorage, ERC2981PerTokenRoyalties {
    struct Room {
        uint256 number;
        string floorId;
        string roomTypeId;
        bool locked;
        Dimensions dimensions;
    }

    struct Dimensions {
        uint8 x;
        uint8 y;
        uint256 width;
        uint256 height;
    }

    mapping(uint256 => Room) private _rooms;
    mapping(uint256 => address[]) private _ownersHistory;

    address[] private _owners;
    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    string private _baseTokenURI;
    address private _controller;
    uint256 private _replicas;

    modifier onlyController(address controller_) {
        // solhint-disable-next-line reason-string
        require(controller() == controller_, "BitHotelRoomCollection: not a controller address.");
        _;
    }

    modifier notLocked(uint256 tokenId) {
        if (_rooms[tokenId].locked) {
            revert TokenLocked(tokenId);
        }
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address controller_,
        uint256 replicas_
    ) 
        ERC721(name, symbol) 
    {
        _controller = controller_;
        _replicas = replicas_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev See {IBitHotelRoomCollection-tokenIds}.
     */
    function tokenIds() external view returns (uint256[] memory) {
        return _allTokens;
    }

    /**
     * @dev See {IBitHotelRoomCollection-ownersHistory}.
     */
    function ownersHistory(uint256 tokenId) external view returns (address[] memory) {
        return _ownersHistory[tokenId];
    }

    /**
     * @dev See {IBitHotelRoomCollection-getRoomInfos}.
     * @param tokenId the nft identification
     */
    function getRoomInfos(uint256 tokenId) external virtual override view returns (uint256, string memory, string memory) {
        uint256 number = _rooms[tokenId].number;
        string memory floorId = _rooms[tokenId].floorId;
        string memory roomTypeId = _rooms[tokenId].roomTypeId;
        return(number, floorId, roomTypeId);
    }

    /**
     * @dev See {IBitHotelRoomCollection-getRoomDimensions}.
     */
    function getRoomDimensions(uint256 tokenId) external view returns (uint8, uint8, uint256, uint256) {
        uint8 x = _rooms[tokenId].dimensions.x;
        uint8 y = _rooms[tokenId].dimensions.y;
        uint256 width = _rooms[tokenId].dimensions.width;
        uint256 height = _rooms[tokenId].dimensions.height;
        return (x, y, width, height);
    }

    /**
     * @dev See {IBitHotelRoomCollection-locked}.
     */
    function locked(uint256 tokenId) external view returns (bool) {
        return _rooms[tokenId].locked;
    }

    /**
     * @dev See {IBitHotelRoomCollection-setRoomInfos}.
     */
    function setRoomInfos(
        uint256 tokenId,
        uint256 number,
        string memory floorId,
        string memory roomTypeId,
        bool locked_,
        uint8 x,
        uint8 y,
        uint256 width,
        uint256 height
    ) external onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        require(tokenId != 0, "BitHotelRoomCollection: tokenId is the zero value");
        Room storage room = _rooms[tokenId];
        room.number = number;
        room.floorId = floorId;
        room.roomTypeId = roomTypeId; 
        room.locked = locked_; 
        room.dimensions.x = x; 
        room.dimensions.y = y;
        room.dimensions.width = width; 
        room.dimensions.height = height; 
        emit RoomInfoAdded(tokenId, number, floorId, roomTypeId, locked_);
        emit DimensionsAdded(x, y, width, height);
    }

    /**
     * @dev See {IBitHotelRoomCollection-setController}.
     */
    function setController(address controller_) external onlyController(_msgSender()) {
         // solhint-disable-next-line reason-string
        require(controller_ != address(0), "BitHotelRoomCollection: controller is the zero address");
         // solhint-disable-next-line reason-string
        require(controller_ != controller(), "BitHotelRoomCollection: controller already updated");
        _controller = controller_;
        emit ControllerChanged(controller_);
    }

    /**
     * @dev See {IBitHotelRoomCollection-lockTokenId}.
     */
    function lockTokenId(uint256 tokenId) external onlyController(_msgSender()) {
         // solhint-disable-next-line reason-string
        require(_exists(tokenId), "BitHotelRoomCollection: change for nonexistent token");
        _rooms[tokenId].locked = true;
        emit TokenIdLocked(tokenId, true);
    }

    /**
     * @dev See {IBitHotelRoomCollection-releaseLockedTokenId}.
     */
    function releaseLockedTokenId(uint256 tokenId) external onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        require(_exists(tokenId), "BitHotelRoomCollection: change for nonexistent token");
        // solhint-disable-next-line reason-string
        require(_rooms[tokenId].locked == true, "BitHotelRoomCollection: tokenId not locked");
        _rooms[tokenId].locked = false;
        emit TokenIdReleased(tokenId, false);
    }

    /**
     * @dev See {IBitHotelRoomCollection-controller}.
     */
    function controller() public view returns (address) {
        return _controller;
    }

    /**
     * @dev See {IBitHotelRoomCollection-replicas}.
     */
    function replicas() public view returns (uint256) {
        return _replicas;
    }

    /**
     * @dev See {IBitHotelRoomCollection-baseURI}.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev See {IBitHotelRoomCollection-exists}.
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
     * @dev See {IBitHotelRoomCollection.setBaseURI}.
     */
    function setBaseURI(string memory newBaseTokenURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        string memory oldBaseTokenURI = baseURI();
        _baseTokenURI = newBaseTokenURI;
        emit BaseUriChanged(oldBaseTokenURI, newBaseTokenURI);
    }

    /**
     * @dev See {IBitHotelRoomCollection.setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string memory tokenURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(_exists(tokenId), "BitHotelRoomCollection: change uri for nonexistent token");
        _setTokenURI(tokenId, tokenURI_);
    }

    /**
     * @dev See {IBitHotelRoomCollection-mint}.
     * WARNING: Usage of this method is discouraged, use {safeMint} whenever possible
    */
    function mint(
        address to,
        uint256 tokenId,
        string memory uri,
        address royaltyRecipient,
        uint256 royaltyValue
    ) public onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        require(totalSupply() < replicas(),"BitHotelRoomCollection: all tokens already minted.");

        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
        }
        _allTokens.push(tokenId);
        emit TokenMint(tokenId, to);
    }

    function bulkSafeMint(
        address[] calldata tos,
        uint256[] calldata mTokenIds,
        string memory uri,
        address royaltyRecipient,
        uint256 royaltyValue,
        bytes memory data_ 
    ) public onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        require(tos.length > 0, "BitHotelRoomCollection: empty tos");
        // solhint-disable-next-line reason-string
        require(mTokenIds.length == tos.length, "BitHotelRoomCollection: tokenIds length mismatched");
        for (uint256 i = 0; i < tos.length; i++) {
            safeMint(tos[i], mTokenIds[i], uri, royaltyRecipient, royaltyValue, data_);
        }
    }

    /**
     * @dev See {IBitHotelRoomCollection-safeMint}.
    */
    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri,
        address royaltyRecipient,
        uint256 royaltyValue,
        bytes memory data_ 
    ) public onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        require(totalSupply() < replicas(),"BitHotelRoomCollection: all tokens already minted.");

        super._safeMint(to, tokenId, data_);
        _setTokenURI(tokenId, uri);
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
    ) 
        internal
        virtual
        override(ERC721, ERC721Enumerable)
        notLocked(tokenId)
    {
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
    function _burn(uint256 tokenId) 
        internal
        virtual
        override(ERC721, ERC721URIStorage)
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        super._burn(tokenId);
    }
}