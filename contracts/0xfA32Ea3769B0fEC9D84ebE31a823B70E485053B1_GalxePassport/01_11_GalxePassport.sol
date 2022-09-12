/*
    Copyright 2022 Project Galaxy.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.7.6;
pragma abicoder v2;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Strings.sol";
import "Ownable.sol";
import "ERC165.sol";
import "IGalxePassport.sol";

/**
 * @dev Fork https://github.com/generalgalactic/ERC721S and implement IGalxePassport interface
 */
contract GalxePassport is
    Ownable,
    ERC165,
    IERC721,
    IERC721Metadata,
    IGalxePassport
{
    using Address for address;
    using Strings for uint256;

    /* ============ State Variables ============ */

    struct Passport {
        uint160 owner; // address is 20 bytes long
        uint64 cid; // max value is ~1.8E19. Enough to store campaign id
        uint32 status;
    }

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Total number of tokens burned
    uint256 private _burnCount;

    // Array of all tokens storing the owner's address and the campaign id
    Passport[] private _tokens;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping owner address to passport token id
    mapping(address => uint256) private _passports;

    // Mint and burn passport.
    mapping(address => bool) private _minters;

    // Base token URI
    string private _baseURI;

    /* ============ Events ============ */
    // Add new minter
    event EventMinterAdded(address indexed newMinter);

    // Remove old minter
    event EventMinterRemoved(address indexed oldMinter);

    // Passport status updated
    event EventPassportStatusUpdated(uint256 tokenId, uint32 status);

    // Passport created
    event Mint(
        address indexed owner,
        uint256 tokenId,
        uint64 cid,
        uint32 status
    );

    // Passport burned
    event Burn(address indexed owner, uint256 tokenId);

    // Passport revoked
    event Revoke(address indexed owner, uint256 tokenId);

    /* ============ Modifiers ============ */

    /**
     * Only minter.
     */
    modifier onlyMinter() {
        require(_minters[msg.sender], "GalxePassport: must be minter");
        _;
    }

    /**
     * @dev Initializes the contract
     */
    constructor() {
        // Initialize zero index value
        Passport memory _passport = Passport(0, 0, 0);
        _tokens.push(_passport);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IGalxePassport).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Is this address a minters.
     */
    function minters(address account) public view returns (bool) {
        return _minters[account];
    }

    /**
     * @dev Is this contract allow nft transfer.
     */
    function transferable() public view returns (bool) {
        return false;
    }

    /**
     * @dev Returns the base URI for nft.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Get Passport CID.
     */
    function cid(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "GalxePassport: passport does not exist");
        return _tokens[tokenId].cid;
    }

    /**
     * @dev Get Passport status.
     */
    function passportStatus(uint256 tokenId) public view returns (uint32) {
        require(_exists(tokenId), "GalxePassport: passport does not exist");
        return _tokens[tokenId].status;
    }

    /**
     * @dev Get Passport minted count.
     */
    function getNumMinted() public view override returns (uint256) {
        return _tokens.length - 1;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return getNumMinted() - _burnCount;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This is implementation is O(n) and should not be
     * called by other contracts.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        uint256 currentIndex = 0;
        for (uint256 i = 1; i < _tokens.length; i++) {
            if (isOwnerOf(owner, i)) {
                if (currentIndex == index) {
                    return i;
                }
                currentIndex += 1;
            }
        }
        revert("ERC721Enumerable: owner index out of bounds");
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return address(_tokens[tokenId].owner);
    }

    /**
     * @dev See {IGalxePassport-isOwnerOf}.
     */
    function isOwnerOf(address account, uint256 id)
        public
        view
        override
        returns (bool)
    {
        address owner = ownerOf(id);
        return owner == account;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(_baseURI).length > 0
                ? string(
                    abi.encodePacked(_baseURI, tokenId.toString(), ".json")
                )
                : "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        require(false, "GalxePassport: approve is not allowed");
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(false, "GalxePassport: getApproved is not allowed");
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        require(false, "GalxePassport: setApprovalForAll is not allowed");
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return false;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(false, "GalxePassport: passport is not transferrable");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(false, "GalxePassport: passport is not transferrable");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(false, "GalxePassport: passport is not transferrable");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            tokenId > 0 &&
            tokenId <= getNumMinted() &&
            _tokens[tokenId].owner != 0x0;
    }

    /**
     * @dev Returns whether `spender` owns `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return spender == owner;
    }

    /* ============ External Functions ============ */
    /**
     * @dev Mints passport to `account`.
     *
     * Emits a {Mint} and a {Transfer} event.
     */
    function mint(address account, uint256 cid)
        external
        override
        onlyMinter
        returns (uint256)
    {
        require(
            account != address(0),
            "GalxePassport: mint to the zero address"
        );

        require(
            balanceOf(account) == 0,
            "GalxePassport: max mint per wallet reached"
        );

        uint256 tokenId = _tokens.length;
        uint64 campaignId = uint64(cid);
        uint32 status = 1;
        Passport memory passport = Passport(
            uint160(account),
            campaignId,
            status
        );

        _balances[account] += 1;
        _passports[account] = tokenId;
        _tokens.push(passport);

        emit Mint(account, tokenId, campaignId, status);
        emit Transfer(address(0), account, tokenId);
        return tokenId;
    }

    /**
     * @dev Revokes passport with tokenId.
     *
     * Requirements:
     *
     * - msg sender must be minter.
     * - `tokenId` token must exist.
     *
     *
     * Emits a {Revoke} and a {Transfer} event.
     */
    function revoke(uint256 tokenId) external override onlyMinter {
        address account = ownerOf(tokenId);
        _burnCount++;
        _balances[account] -= 1;
        delete _passports[account];
        _tokens[tokenId].owner = 0;
        _tokens[tokenId].cid = 0;
        _tokens[tokenId].status = 0;

        emit Revoke(account, tokenId);
        emit Transfer(account, address(0), tokenId);
    }

    /**
     * @dev Burns passport with tokenId.
     *
     * Requirements:
     *
     * - msg sender must be token owner.
     * - `tokenId` token must exist.
     *
     *
     * Emits a {Burn} and a {Transfer} event.
     */
    function burn(uint256 tokenId) external override {
        require(
            isOwnerOf(_msgSender(), tokenId),
            "GalxePassport: caller is not token owner"
        );

        _burnCount++;
        _balances[_msgSender()] -= 1;
        delete _passports[_msgSender()];
        _tokens[tokenId].owner = 0;
        _tokens[tokenId].cid = 0;
        _tokens[tokenId].status = 0;

        emit Burn(_msgSender(), tokenId);
        emit Transfer(_msgSender(), address(0), tokenId);
    }

    /**
     * @dev Sets status of passport with `tokenId` to `status`.
     *
     * Requirements:
     *
     * - msg sender must be minter.
     * - `tokenId` token must exist.
     *
     *
     * Emits a {EventPassportStatusUpdated} event.
     */
    function setPassportStatus(uint256 tokenId, uint32 status)
        external
        onlyMinter
    {
        require(_exists(tokenId), "GalxePassport: passport does not exist");

        _tokens[tokenId].status = status;

        emit EventPassportStatusUpdated(tokenId, status);
    }

    function getAddressPassport(address owner) public view returns (Passport memory) {
        require(
            balanceOf(owner) != 0,
            "GalxePassport: address does not have passport"
        );
        uint256 tokenId = _passports[owner];
        return _tokens[tokenId];
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(false, "GalxePassport: passport is not transferrable");
    }

    /* ============ Util Functions ============ */
    /**
     * @dev Sets a new baseURI for all token types.
     */
    function setURI(string calldata newURI) external onlyOwner {
        _baseURI = newURI;
    }

    /**
     * @dev Sets a new name for all token types.
     */
    function setName(string calldata newName) external onlyOwner {
        _name = newName;
    }

    /**
     * @dev Sets a new symbol for all token types.
     */
    function setSymbol(string calldata newSymbol) external onlyOwner {
        _symbol = newSymbol;
    }

    /**
     * @dev Add a new minter.
     */
    function addMinter(address minter) external onlyOwner {
        require(minter != address(0), "minter must not be null address");
        require(!_minters[minter], "minter already added");
        _minters[minter] = true;
        emit EventMinterAdded(minter);
    }

    /**
     * @dev Remove a old minter.
     */
    function removeMinter(address minter) external onlyOwner {
        require(_minters[minter], "minter does not exist");
        delete _minters[minter];
        emit EventMinterRemoved(minter);
    }
}