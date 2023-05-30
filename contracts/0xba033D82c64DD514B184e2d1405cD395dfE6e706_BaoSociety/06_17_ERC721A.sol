// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error MintExceedsLimit();
error MintExceedsMaxPerWallet();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error QueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint56 startTimestamp;
        bool nextTokenOwnerShipSet;
    }

    struct UserData {
        uint128 balance;
        uint128 numMinted;
    }

    uint256 private immutable _startingIndex;
    uint256 private immutable _collectionSize;
    uint256 private immutable _maxPerWallet;

    uint256 private _totalSupply;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) private _tokenData;

    // Mapping owner address to address data
    mapping(address => UserData) private _userData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev
     * `maxBatchSize` refers to how much a minter can mint at a time.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 collectionSize_,
        uint256 startingIndex_,
        uint256 maxPerWallet_
    ) {
        _name = name_;
        _symbol = symbol_;
        _collectionSize = collectionSize_;
        _startingIndex = startingIndex_;
        _maxPerWallet = maxPerWallet_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function startingIndex() public view returns (uint256) {
        return _startingIndex;
    }

    function tokenIdsOf(address owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);

        if (balance == 0) return tokenIds;

        uint256 totalSupply_ = _totalSupply;
        uint256 count;

        for (uint256 i = _startingIndex; i < _startingIndex + totalSupply_; i++) {
            if (owner == ownerOf(i)) {
                tokenIds[count++] = i;
                if (balance == count) return tokenIds;
            }
        }

        return tokenIds;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _userData[owner].balance;
    }

    function numMinted(address owner) public view returns (uint256) {
        return _userData[owner].numMinted;
    }

    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();

        for (uint256 curr = tokenId; ; curr--) {
            TokenOwnership memory ownership = _tokenData[curr];
            if (ownership.addr != address(0)) {
                return ownership;
            }
        }

        revert QueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string.concat(baseURI, tokenId.toString()) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert ApprovalCallerNotOwnerNorApproved();

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == msg.sender) revert ApproveToCaller();

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        _transfer(from, to, tokenId);
        if (
            to.code.length != 0 &&
            IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) !=
            IERC721Receiver(to).onERC721Received.selector
        ) revert TransferToNonERC721ReceiverImplementer();
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startingIndex <= tokenId && tokenId < _startingIndex + _totalSupply;
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        unchecked {
            uint256 supply = _totalSupply;
            uint256 startTokenId = _startingIndex + supply;

            if (to == address(0)) revert MintToZeroAddress();
            if (quantity == 0) revert MintZeroQuantity();
            if (supply + quantity > _collectionSize) revert MintExceedsLimit();

            UserData memory userData = _userData[to];
            if (userData.numMinted + quantity > _maxPerWallet && to == msg.sender && address(this).code.length != 0)
                revert MintExceedsMaxPerWallet();

            _userData[to] = UserData(userData.balance + uint128(quantity), userData.numMinted + uint128(quantity));

            _tokenData[startTokenId] = TokenOwnership(to, uint56(block.timestamp), false);

            for (uint256 i; i < quantity; ++i) emit Transfer(address(0), to, startTokenId + i);

            _totalSupply += quantity;
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (msg.sender == from ||
            isApprovedForAll(from, msg.sender) ||
            getApproved(tokenId) == msg.sender);

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            --_userData[from].balance;
            ++_userData[to].balance;

            _tokenData[tokenId] = TokenOwnership(to, uint56(block.timestamp), true);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (
                !prevOwnership.nextTokenOwnerShipSet &&
                _tokenData[nextTokenId].addr == address(0) &&
                nextTokenId < _startingIndex + _collectionSize // it's ok to check collectionSize instead of totalSupply, because unminted tokenOwnerships will be overwritten
            ) {
                _tokenData[nextTokenId] = TokenOwnership(from, prevOwnership.startTimestamp, false);
            }
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
}