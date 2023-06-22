// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../def/CustomErrors.sol";

abstract contract ERC721Ommg is Context, ERC165, IERC721 {
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 private currentIndex = 1;
    uint256 private burned;

    uint256 private immutable _maxBatchSize;
    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) private _ownerOf;
    // Mapping owner address to address data
    mapping(address => AddressData) private _balanceOf;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(uint256 maxBatchSize_) {
        _maxBatchSize = maxBatchSize_;
    }

    function _currentIndex() internal view returns (uint256) {
        return currentIndex - 1;
    }

    function _burned() internal view returns (uint256) {
        return burned;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function maxBatchSize() public view virtual returns (uint256) {
        return _maxBatchSize;
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert NullAddress();
        return _balanceOf[owner].balance;
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    function _ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);

        uint256 lowestTokenToCheck;
        if (tokenId >= _maxBatchSize) {
            lowestTokenToCheck = tokenId - _maxBatchSize + 1;
        }

        for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
            TokenOwnership memory ownership = _ownerOf[curr];
            if (ownership.addr != address(0)) return ownership;
        }
        revert OperationFailed();
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data))
            revert SafeTransferFailed(from, to, tokenId);
    }

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        // is in ownerOf
        // if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        if (to == owner) revert ApprovalInvalid(_msgSender(), tokenId);

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert ApprovalUnauthorized(owner, to, tokenId, _msgSender());

        _approve(to, tokenId, owner);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        if (operator == _msgSender())
            revert ApprovalForAllInvalid(_msgSender(), approved);

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            tokenId > 0 &&
            tokenId < currentIndex &&
            _ownerOf[tokenId].addr != address(this);
    }

    // function _hasBeenMinted(uint256 tokenId) internal view returns (bool) {
    //     return tokenId < currentIndex;
    // }

    // function _ownerAddress(uint256 tokenId) internal view returns (address) {
    //     return _ownerOf[tokenId].addr;
    // }

    function _burn(uint256 tokenId) internal {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);

        TokenOwnership memory owner = _ownershipOf(tokenId);

        _beforeTokenTransfers(owner.addr, address(this), tokenId, 1);

        // Clear approvals
        _approve(address(0), tokenId, owner.addr);

        _balanceOf[owner.addr].balance -= 1;
        _ownerOf[tokenId].addr = address(this);
        burned++;
        uint256 nextTokenId = tokenId + 1;
        if (_ownerOf[nextTokenId].addr == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerOf[nextTokenId] = TokenOwnership(
                    owner.addr,
                    owner.startTimestamp
                );
            }
        }
        emit Transfer(owner.addr, address(this), tokenId);

        _afterTokenTransfers(owner.addr, address(this), tokenId, 1);
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` cannot be larger than the max batch size.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory data
    ) internal {
        uint256 startTokenId = currentIndex;
        if (to == address(0)) revert NullAddress();
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        // TODO can this even happen?
        // if (_exists(startTokenId)) revert TokenAlreadyExists(startTokenId);

        if (quantity > _maxBatchSize || quantity == 0)
            revert InvalidAmount(quantity, 1, _maxBatchSize);

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        AddressData memory oldData = _balanceOf[to];
        _balanceOf[to] = AddressData(
            oldData.balance + uint128(quantity),
            oldData.numberMinted + uint128(quantity)
        );
        _ownerOf[startTokenId] = TokenOwnership(to, uint64(block.timestamp));
        uint256 updatedIndex = startTokenId;
        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, updatedIndex);
            if (!_checkOnERC721Received(address(0), to, updatedIndex, data))
                revert SafeTransferFailed(address(0), to, updatedIndex);
            updatedIndex++;
        }
        currentIndex = updatedIndex;
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
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
        if (to == address(0)) revert NullAddress();

        TokenOwnership memory prevOwner = _ownershipOf(tokenId);

        if (prevOwner.addr != from)
            revert TransferUnauthorized(
                _msgSender(),
                from,
                to,
                tokenId,
                prevOwner.addr
            );

        if (
            _msgSender() != prevOwner.addr &&
            getApproved(tokenId) != _msgSender() &&
            !isApprovedForAll(prevOwner.addr, _msgSender())
        )
            revert TransferUnauthorized(
                _msgSender(),
                from,
                to,
                tokenId,
                prevOwner.addr
            );

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwner.addr);

        _balanceOf[from].balance -= 1;
        _balanceOf[to].balance += 1;
        _ownerOf[tokenId] = TokenOwnership(to, uint64(block.timestamp));

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerOf[nextTokenId].addr == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerOf[nextTokenId] = TokenOwnership(
                    prevOwner.addr,
                    prevOwner.startTimestamp
                );
            }
        }
        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
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

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TargetNonERC721Receiver(to);
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual {}
}