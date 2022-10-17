// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title ERC721W
 * @custom:a w3box.com
 */
contract ERC721W is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Token Decimals for avoif friction with several wallets
    uint8 private _decimals;

    // Base URI
    string private BASE_URI;

    // Contract URI
    string private CONTRACT_URI;

    uint256 public TOTAL_SUPPLY;

    uint256 internal constant SIZE_MASK = 65535;
    uint256 private constant WALLET_MASK =
        1461501637330902918203684832716283019655932542975;
    uint256 private constant TS_MASK = 18446744073709551615;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => uint256) internal tokens;

    mapping(uint256 => uint256) internal owners;

    uint256 internal ownerIndex = 1; // Holds the available index (can be in the middle)
    uint256 internal ownerIndexTip = 1; // Holds the tip of owner indexes

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        uint256 totalSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        BASE_URI = baseURI_;
        CONTRACT_URI = contractURI_;
        TOTAL_SUPPLY = totalSupply_;
    }

    function _resolveTokenPosition(uint256 tokenId)
        internal
        pure
        returns (uint256 bucket, uint256 position)
    {
        bucket = tokenId >> 4;
        position = (tokenId & 0xf) << 4;
    }

    function _decodeOwnerData(uint256 data)
        internal
        pure
        returns (
            address _owner,
            uint256 count,
            uint256 timestamp
        )
    {
        _owner = address(uint160(data & WALLET_MASK));
        timestamp = (data >> 160) & TS_MASK;
        count = data >> 224;
    }

    function _ownerIndexByTokenPosition(uint256 bucket, uint256 position)
        internal
        view
        returns (uint256)
    {
        return (SIZE_MASK & (tokens[bucket] >> position)); // here in future we can discount the giveaway bit
    }

    function _ownerIndexByTokenId(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        (uint256 bucket, uint256 position) = _resolveTokenPosition(tokenId);

        return _ownerIndexByTokenPosition(bucket, position);
    }

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 index)
        external
        view
        override
        returns (uint256)
    {
        uint256 current = 0;
        uint256 tokenId = 0;
        for (uint256 i = 0; i < 625; i++) {
            if (tokens[i] > 0) {
                for (uint256 j = 0; i < 16; j++) {
                    if (
                        _ownerIndexByTokenPosition(tokens[i], j) > 0 &&
                        _owner == address(uint160(owners[index] & WALLET_MASK))
                    ) {
                        current += j;
                    }
                    if (current == index) {
                        return tokenId + j;
                    }
                }
            }
            tokenId += 16;
        }
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     * @param index The index of all the tokens stored by the contract.
     * @return The token ID at the given index.
     */
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(index > 0, "ERC721: owner query for nonexistent token");
        uint256 current = 0;
        uint256 tokenId = 0;
        for (uint256 i = 0; i < 625; i++) {
            if (tokens[i] > 0) {
                for (uint256 j = 0; i < 16; j++) {
                    if (_ownerIndexByTokenPosition(tokens[i], j) > 0) {
                        current += j;
                    }
                    if (current == index) {
                        return tokenId + j;
                    }
                }
            }
            tokenId += 16;
        }
        revert("ERC721: owner query for nonexistent token");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerIndexByTokenId(tokenId) != 0;
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256 balance)
    {
        require(
            _owner != address(0),
            "ERC721: wallet not must be Zero address"
        );
        balance = 0;
        for (uint256 i = 1; i < ownerIndexTip; i++) {
            if (
                owners[i] > 0 &&
                address(uint160(owners[i] & WALLET_MASK)) == _owner
            ) {
                balance += owners[i] >> 224;
            }
        }
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        override
        returns (address _owner)
    {
        uint256 index = _ownerIndexByTokenId(tokenId);
        require(index > 0, "ERC721: owner query for nonexistent token");

        _owner = address(uint160(owners[index] & WALLET_MASK));
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
        bytes memory _data
    ) public override {
        require(from != address(0), "ERC721: sender not must be Zero address");
        require(to != address(0), "ERC721: receipt not must be Zero address");
        require(to != from, "ERC721: Void transfer");

        require(
            _checkOnERC721Received(from, to, tokenId, ""),
            "ERC721: transfer to non ERC721Receiver implementer"
        );

        (uint256 bucket, uint256 position) = _resolveTokenPosition(tokenId); // exists() calls the same function. Avoid calling twice.

        uint256 index = _ownerIndexByTokenPosition(bucket, position);
        require(index != 0, "ERC721: Token not exists");

        uint256 data = owners[index];

        (address _owner, uint256 batchCount, uint256 lockTs) = _decodeOwnerData(
            data
        );
        require(_owner == from, "ERC721: Not token owner");
        require(
            _msgSender() == _owner ||
                _operatorApprovals[_owner][_msgSender()] ||
                _tokenApprovals[tokenId] == _msgSender(),
            "ERC721: approve caller is not owner nor approved for all"
        );

        require(block.timestamp > lockTs, "ERC721: Token is locked for sale");

        _beforeTokenTransfers(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        if (batchCount == 1) {
            // give the bucket
            owners[index] = (data & ~WALLET_MASK) | uint160(to);
        } else if (batchCount > 1) {
            // update the counter and create a new bucket
            uint256 newIndex = assignOwnerIndex();
            owners[newIndex] = (1 << 224) | uint160(to);
            tokens[bucket] =
                (tokens[bucket] & ~(SIZE_MASK << position)) |
                (newIndex << position);
            owners[index] =
                (data & ~(SIZE_MASK << 224)) |
                ((batchCount - 1) << 224);
        } else {
            revert("ERC721: Invalid Batch Count");
        }

        emit Transfer(from, to, tokenId);

        _afterTokenTransfers(from, to, tokenId);
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
    ) external override {
        safeTransferFrom(from, to, tokenId);
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
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address _owner = ownerOf(tokenId);
        require(to != _owner, "ERC721: approval to current owner");
        require(to != address(0), "ERC721: approval to the zero address");

        require(
            _msgSender() == _owner || isApprovedForAll(_owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `_owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address _owner,
        address operator,
        bool approved
    ) internal virtual {
        require(_owner != operator, "ERC721: approve to caller");
        _operatorApprovals[_owner][operator] = approved;
        emit ApprovalForAll(_owner, operator, approved);
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
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
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
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address _owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[_owner][operator];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address _owner = ownerOf(tokenId);
        return (spender == _owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(_owner, spender));
    }

    function isApprovedOrOwner(address spender, uint256 tokenId)
        public
        view
        virtual
        returns (bool)
    {
        return _isApprovedOrOwner(spender, tokenId);
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     @dev Returns the token collection decimals
     */
    function decimals() external view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return BASE_URI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI();
    }

    /**
     * @notice Method to reduce the friction with Opensea by allowing the Contract URI to be updated
     * @dev This method is only available for the owner of the contract
     * @param _contractURI The new contract URI
     */
    function _setContractURI(string memory _contractURI) internal {
        CONTRACT_URI = _contractURI;
    }

    /**
     * @notice Method to reduce the friction with Opensea by allowing Contract URI to be obtained
     */
    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");

        string memory baseURI_ = baseURI();
        return
            bytes(baseURI_).length > 0
                ? string(abi.encodePacked(baseURI_, tokenId.toString()))
                : "";
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply()
        external
        view
        virtual
        override
        returns (uint256 total)
    {
        total = 0;
        for (uint256 i = 1; i < ownerIndexTip; i++) {
            total += owners[i] >> 224;
        }
    }

    // INTERNAL

    function assignOwnerIndex() internal returns (uint256 index) {
        // This will help with burn()
        index = ownerIndex++;
        if (owners[ownerIndex] > 0) {
            // it's busy
            ownerIndex = ownerIndexTip;
        } else if (ownerIndex > ownerIndexTip) {
            ownerIndexTip = ownerIndex;
        }
    }

    function _mint(uint256 tokenId, uint256 index) internal {
        require(
            tokenId > 0 && tokenId <= TOTAL_SUPPLY,
            "ERC721: Invalid token ID"
        );

        (uint256 bucket, uint256 position) = _resolveTokenPosition(tokenId); // exists() calls the same function. Avoid calling twice.

        require(
            _ownerIndexByTokenPosition(bucket, position) == 0,
            "ERC721: Token was sold"
        );

        tokens[bucket] |= (index << position);
    }

    function _safeMint(address _owner, uint256 tokenId) internal {
        require(
            _owner != address(0),
            "ERC721: receipt not must be Zero address"
        );

        require(
            _checkOnERC721Received(address(0), _owner, tokenId, ""),
            "ERC721: transfer to non ERC721Receiver implementer"
        );

        _beforeTokenTransfers(address(0), _owner, tokenId);

        uint256 index = assignOwnerIndex();

        _mint(tokenId, index);

        owners[index] = (1 << 224) | uint160(_owner);

        emit Transfer(address(0), _owner, tokenId);

        _afterTokenTransfers(address(0), _owner, tokenId);
    }

    function _batchMint(
        address[] calldata _owner,
        uint256[] calldata tokenIds,
        uint64 locktime
    ) internal virtual {
        require(
            (_owner.length == tokenIds.length),
            "ERC721: owner and tokenIds must be the same length"
        );
        for (uint256 i = 0; i < _owner.length; i++) {
            require(
                _owner[i] != address(0),
                "ERC721: receipt not must be Zero address"
            );
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 index = assignOwnerIndex();
            _beforeTokenTransfers(address(0), _owner[i], tokenIds[i]);
            _mint(tokenIds[i], index);
            emit Transfer(address(0), _owner[i], tokenIds[i]);
            _afterTokenTransfers(address(0), _owner[i], tokenIds[i]);
            owners[index] =
                (1 << 224) |
                (uint256(locktime) << 160) |
                uint160(_owner[i]);
        }
    }

    function _burn(uint256 tokenId) internal {
        (uint256 bucket, uint256 position) = _resolveTokenPosition(tokenId);

        uint256 index = _ownerIndexByTokenPosition(bucket, position);
        require(index != 0, "ERC721: Token not exists");

        uint256 data = owners[index];

        (address _owner, uint256 batchCount, uint256 lockTs) = _decodeOwnerData(
            data
        );
        require(_owner == msg.sender, "ERC721: Not token owner");
        require(block.timestamp > lockTs, "ERC721: Token is locked for sale");

        _beforeTokenTransfers(_owner, address(0), tokenId);

        if (batchCount == 1) {
            // give the bucket
            delete owners[index];
            ownerIndex = index; // reuse!
        } else if (batchCount > 1) {
            // update the counter
            owners[index] =
                (data & ~(SIZE_MASK << 224)) |
                ((batchCount - 1) << 224);
        } else {
					revert("ERC721: Invalid batch count");
				}

        tokens[bucket] &= ~(SIZE_MASK << position); // Set to zero

        emit Transfer(msg.sender, address(0), tokenId);

        _afterTokenTransfers(_owner, address(0), tokenId);
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
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
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
        uint256 tokenId
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
        uint256 tokenId
    ) internal virtual {}

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
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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
}