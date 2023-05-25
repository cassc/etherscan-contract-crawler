// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721VF.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension.
 */
contract ERC721VF is Context, ERC165, IERC721VF, DefaultOperatorFilterer {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // The number of tokens minted
    uint256 private _mintCounter;

    // The number of tokens burned
    uint256 private _burnCounter;

    //Flag to permanently lock minting
    bool public mintingPermanentlyLocked = false;
    //Flag to activate or disable minting
    bool public isMintActive = false;
    //Flag to activate or disable burning
    bool public isBurnActive = false;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    modifier notLocked() virtual {
        if (mintingPermanentlyLocked) {
            revert ERC721VFMintingPermanentlyLocked();
        }
        _;
    }

    modifier mintActive() virtual {
        if (!isMintActive) {
            revert ERC721VFMintIsNotActive();
        }
        _;
    }

    modifier burnActive() virtual {
        if (!isBurnActive) {
            revert ERC721VFBurnIsNotActive();
        }
        _;
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
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata
            interfaceId == type(IERC721VF).interfaceId || // ERC165 interface ID for ERC721VF.
            super.supportsInterface(interfaceId); // ERC165 interface ID for ERC165
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) {
            revert ERC721VFAddressZeroIsNotAValidOwner();
        }

        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert ERC721VFInvalidTokenID(tokenId);
        }
        return owner;
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
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId)
        public
        virtual
        override
        onlyAllowedOperatorApproval(to)
    {
        address owner = ERC721VF.ownerOf(tokenId);
        if (to == owner) {
            revert ERC721VFApprovalToCurrentOwner(to, tokenId);
        }

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ERC721VFApproveCallerIsNotTokenOwnerOrApprovedForAll(
                to,
                tokenId
            );
        }

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        _transferFrom(from, to, tokenId, true);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        _safeTransferFrom(from, to, tokenId, true);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        _safeTransferFrom(from, to, tokenId, true, data);
    }

    /**
     * @dev See {IERC721VF-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        unchecked {
            return _mintCounter - _burnCounter;
        }
    }

    /**
     * @dev See {IERC721VF-totalMinted}.
     */
    function totalMinted() public view returns (uint256) {
        unchecked {
            return _mintCounter;
        }
    }

    /**
     * @dev See {IERC721VF-totalBurned}.
     */
    function totalBurned() public view returns (uint256) {
        unchecked {
            return _burnCounter;
        }
    }

    /**
     * @dev See {IERC721VF-tokensOfOwner}.
     */
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory ownerTokens)
    {
        address currentOwnerAddress;
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;

            uint256 index;
            for (index = 0; resultIndex != tokenCount; index++) {
                currentOwnerAddress = _owners[index];
                if (currentOwnerAddress == owner) {
                    result[resultIndex++] = index;
                }
            }

            return result;
        }
    }

    /**
     * @dev See {IERC721VF-tokensOfOwnerIn}.
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (uint256[] memory ownerTokens) {
        address currentOwnerAddress;
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;

            uint256 index = startIndex;
            for (index; index <= endIndex; index++) {
                currentOwnerAddress = _owners[index];
                if (currentOwnerAddress == owner) {
                    result[resultIndex++] = index;
                }
            }

            // Downsize the array to fit.
            assembly {
                mstore(result, resultIndex)
            }

            return result;
        }
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function _transferFrom(
        address from,
        address to,
        uint256 tokenId,
        bool approvalCheck
    ) internal virtual {
        //solhint-disable-next-line max-line-length

        if (approvalCheck) {
            if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
                revert ERC721VFCallerIsNotTokenOwnerOrApproved(
                    from,
                    to,
                    tokenId
                );
            }
        }

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bool approvalCheck
    ) internal virtual {
        _safeTransferFrom(from, to, tokenId, approvalCheck, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bool approvalCheck,
        bytes memory data
    ) internal virtual {
        if (approvalCheck) {
            if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
                revert ERC721VFCallerIsNotTokenOwnerOrApproved(
                    from,
                    to,
                    tokenId
                );
            }
        }
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert ERC721VFTransferToNonERC721VFReceiverImplementer(
                to,
                tokenId
            );
        }
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
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
        address owner = ERC721VF.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @dev Permanently lock minting
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function _lockMintingPermanently() internal {
        mintingPermanentlyLocked = true;
    }

    /**
     * @dev Set the active/inactive state of minting
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function _toggleMintActive() internal {
        isMintActive = !isMintActive;
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert ERC721VFTransferToNonERC721VFReceiverImplementer(
                to,
                tokenId
            );
        }
    }

    /**
     * @dev Safely batch mints tokens starting at `startTokenId` until `quantity` is met and transfers them to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * - Transfer to only ERC721Reciever implementers
     *
     * Emits a {Transfer} event.
     */
    function _safeMintBatch(
        address to,
        uint256 quantity,
        uint256 startTokenId
    ) internal returns (uint256 endToken) {
        uint256 tokenId = startTokenId;
        for (uint256 i; i < quantity; i++) {
            if (to == address(0)) {
                revert ERC721VFMintToTheZeroAddress();
            }

            if (_exists(tokenId)) {
                revert ERC721VFTokenAlreadyMinted(tokenId);
            }

            _beforeTokenTransfer(address(0), to, tokenId, 1);

            _balances[to] += 1;
            _owners[tokenId] = to;

            emit Transfer(address(0), to, tokenId);

            _afterTokenTransfer(address(0), to, tokenId, 1);

            if (!_checkOnERC721Received(address(0), to, tokenId, "")) {
                revert ERC721VFTransferToNonERC721VFReceiverImplementer(
                    to,
                    tokenId
                );
            }

            tokenId++;
        }

        unchecked {
            _mintCounter += quantity;
        }

        return tokenId;
    }

    /**
     * @dev Airdrop `addresses` for `quantity` starting at `startTokenId`
     *
     * Requirements:
     *
     * - the caller must be a minter role
     * - minting must not be locked and must be active
     * - `addresses` and `quantities` must have the same length
     */
    function _airdrop(
        address[] calldata addresses,
        uint256[] calldata quantities,
        uint256 startTokenId
    ) internal virtual {
        if (addresses.length != quantities.length) {
            revert ERC721VFAddressAndQuantitiesNeedToBeEqualLength();
        }

        for (uint256 i; i < addresses.length; i++) {
            startTokenId = _mintBatch(
                addresses[i],
                quantities[i],
                startTokenId
            );
        }
    }

    /**
     * @dev Batch mints tokens starting at `startTokenId` until `quantity` is met and transfers them to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _mintBatch(
        address to,
        uint256 quantity,
        uint256 startTokenId
    ) internal virtual returns (uint256 endToken) {
        uint256 tokenId = startTokenId;
        for (uint256 i; i < quantity; i++) {
            if (to == address(0)) {
                revert ERC721VFMintToTheZeroAddress();
            }

            if (_exists(tokenId)) {
                revert ERC721VFTokenAlreadyMinted(tokenId);
            }

            _beforeTokenTransfer(address(0), to, tokenId, 1);

            _owners[tokenId] = to;

            emit Transfer(address(0), to, tokenId);

            _afterTokenTransfer(address(0), to, tokenId, 1);

            tokenId++;
        }

        unchecked {
            _balances[to] += quantity;
            _mintCounter += quantity;
        }

        return tokenId;
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) {
            revert ERC721VFMintToTheZeroAddress();
        }

        if (_exists(tokenId)) {
            revert ERC721VFTokenAlreadyMinted(tokenId);
        }

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        unchecked {
            _mintCounter++;
        }

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Set the active/inactive state of burning
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function _toggleBurnActive() internal {
        isBurnActive = !isBurnActive;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(
        address from,
        uint256 tokenId,
        bool approvalCheck
    ) internal virtual {
        if (approvalCheck) {
            if (!_isApprovedOrOwner(from, tokenId)) {
                revert ERC721VFBurnCallerIsNotTokenOwnerOrApproved(
                    from,
                    tokenId
                );
            }
        }
        _burn(tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721VF.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        unchecked {
            _burnCounter++;
        }

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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
        if (to == address(0)) {
            revert ERC721VFTransferToTheZeroAddress();
        }

        if (ERC721VF.ownerOf(tokenId) != from) {
            revert ERC721VFTransferFromIncorrectOwner(from, tokenId);
        }

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721VF.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if (owner == operator) {
            revert ERC721VFApproveToCaller();
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        if (!_exists(tokenId)) {
            revert ERC721VFInvalidTokenID(tokenId);
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721VFTransferToNonERC721VFReceiverImplementer(
                        to,
                        tokenId
                    );
                } else {
                    /// @solidity memory-safe-assembly
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
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}