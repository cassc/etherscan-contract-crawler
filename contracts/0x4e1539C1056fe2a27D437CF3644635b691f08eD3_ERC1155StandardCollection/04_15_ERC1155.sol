// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Strings.sol";
import "../../utils/Ownable.sol";
import "../../utils/ERC165.sol";

error ApprovalToCurrentOwner();
error ArrayLengthMismatch();
error BalanceQueryForZeroAddress();
error BurnFromZeroAddress();
error InsufficientTokenBalance();
error InvalidMetadata();
error MintToZeroAddress();
error NonExistentToken();
error NotOwnerOrApproved();
error OverMaxMint();
error OverMaxTokens();
error OverTokenLimit();
error OverWalletLimit();
error TokenAlreadyExists();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * There are some modifications compared to the originial OpenZepplin implementation
 * that give the collection owner many options for the tokens they want to add in
 * their ERC1155 collection.
 *
 * _Available since v3.1._
 */
contract ERC1155 is Ownable, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenAddressData {
        // Limited to uint64 to save gas fees.
        uint64 balance;
        // Keeps track of mint count for a user of a tokenId.
        uint64 numMinted;
        // Keeps track of burn count for a user of a tokenId.
        uint64 numBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // Compiler will pack this into a single 256bit word.
    struct TokenSupplyData {
        // Keeps track of mint count of a tokenId.
        uint64 numMinted;
        // Keeps track of burn count of a tokenId.
        uint64 numBurned;
        // Keeps track of maximum mintable of a tokenId.
        uint64 tokenMintLimit;
        // Keeps track of the max a single wallet cant mint of a tokenId.
        uint64 walletMintLimit;
    }

    // Used to enable the uri method
    mapping(uint256 => string) public tokenMetadata;

    // Saves all the token mint/burn data and mint limitations.
    mapping(uint256 => TokenSupplyData) private _tokenData;

    // Mapping from token ID to account balances, mints, and burns
    mapping(uint256 => mapping(address => TokenAddressData)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    /* Events */
    event NewTokenAdded(
        uint256 indexed tokenId,
        uint256 tokenMintLimit,
        uint256 walletMintLimit,
        string tokenURI
    );
    event TokenURIChanged(uint256 tokenId, string newTokenURI);
    event NameChanged(string name);
    event SymbolChanged(string symbol);

    /**
     * @dev Removed Zepplin constructor that set uri for the collection because
     * each tokenId will have it's own uri when added.
     */
    constructor() {}

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
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev updates the name of the collection
     */
    function _setName(string memory _newName) internal {
        _name = _newName;
        emit NameChanged(_newName);
    }

    /**
     * @dev updates the symbol of the collection
     */
    function _setSymbol(string memory _newSymbol) internal {
        _symbol = _newSymbol;
        emit SymbolChanged(_newSymbol);
    }

    /**
     * @dev Returns if a tokenId has been added to the collection yet.
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return bytes(tokenMetadata[tokenId]).length > 0;
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        if (!exists(tokenId)) revert NonExistentToken();
        return tokenMetadata[tokenId];
    }

    /**
     * @dev Allows the owner to add a tokenId to the collection with the specificed
     * metadata and mint limits. NOTE: MINT LIMITS ARE FINAL
     *
     * Requirements:
     *
     * - `tokenId` must not have been added yet.
     * - `metadata` must not be length 0.
     *
     * @param tokenId of the new addition to the colleciton
     * @param walletMintLimit per address for the new collection
     * @param tokenMintLimit for the new token
     * @param metadata for the new collection when calling uri
     */
    function addTokenId(
        uint256 tokenId,
        uint64 tokenMintLimit,
        uint64 walletMintLimit,
        string calldata metadata
    ) external onlyOwner {
        if (exists(tokenId)) revert TokenAlreadyExists();
        if (bytes(metadata).length == 0) revert InvalidMetadata();
        tokenMetadata[tokenId] = metadata;
        _tokenData[tokenId].walletMintLimit = walletMintLimit;
        _tokenData[tokenId].tokenMintLimit = tokenMintLimit;

        emit NewTokenAdded(tokenId, tokenMintLimit, walletMintLimit, metadata);
    }

    /**
     * @dev Allows the owner to change the metadata for a tokenId but NOT the mint limits.
     *
     * Requirements:
     *
     * - `tokenId` must have already been added.
     * - `metadata` must not be length 0.
     */
    function updateMetadata(uint256 tokenId, string calldata metadata)
        external
        onlyOwner
    {
        if (!exists(tokenId)) revert NonExistentToken();
        if (bytes(metadata).length == 0) revert InvalidMetadata();
        tokenMetadata[tokenId] = metadata;

        emit TokenURIChanged(tokenId, metadata);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (account == address(0)) revert BalanceQueryForZeroAddress();
        return _balances[id][account].balance;
    }

    /**
     * @dev returns the total amount of tokens of a certain tokenId are in circulation.
     */
    function totalSupply(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        if (!exists(tokenId)) revert NonExistentToken();
        return _tokenData[tokenId].numMinted - _tokenData[tokenId].numBurned;
    }

    /**
     * @dev returns the total amount of tokens of a certain tokenId that have gotten burned.
     */
    function totalBurned(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        if (!exists(tokenId)) revert NonExistentToken();
        return _tokenData[tokenId].numBurned;
    }

    /**
     * @dev Returns how much an address has minted of a certain id
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function totalMinted(address account, uint256 id)
        public
        view
        virtual
        returns (uint256)
    {
        if (account == address(0)) revert BalanceQueryForZeroAddress();
        return _totalMinted(account, id);
    }

    /**
     * @dev Returns how much an address has minted of a certain id
     */
    function _totalMinted(address account, uint256 id)
        internal
        view
        virtual
        returns (uint256)
    {
        return _balances[id][account].numMinted;
    }

    /**
     * @dev Returns how much an address has minted of a certain id
     *
     * Requirements:
     *
     * - `tokenId` must already exist.
     */
    function totalRemainingMints(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        if (!exists(tokenId)) revert NonExistentToken();
        return _totalRemainingMints(tokenId);
    }

    /**
     * @dev Returns how much an address has minted of a certain id
     */
    function _totalRemainingMints(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return
            _tokenData[tokenId].tokenMintLimit - _tokenData[tokenId].numMinted;
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        if (accounts.length != ids.length) revert ArrayLengthMismatch();

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev Verifies if a certain tokenId can still mint `buyAmount` more tokens of a certain id.
     */
    function _verifyTokenMintLimit(uint256 tokenId, uint256 buyAmount)
        internal
        view
    {
        if (
            _tokenData[tokenId].numMinted + buyAmount >
            _tokenData[tokenId].tokenMintLimit
        ) {
            revert OverTokenLimit();
        }
    }

    /**
     * @dev Verifies if a certain wallet can still mint `buyAmount` more tokens of a certain id.
     */
    function _verifyWalletMintLimit(
        address receiver,
        uint256 tokenId,
        uint256 buyAmount
    ) internal view {
        if (
            _tokenData[tokenId].walletMintLimit != 0 &&
            _balances[tokenId][receiver].numMinted + buyAmount >
            _tokenData[tokenId].walletMintLimit
        ) {
            revert OverWalletLimit();
        }
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert NotOwnerOrApproved();
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public virtual override {
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert NotOwnerOrApproved();
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert TransferToZeroAddress();

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        if (_balances[id][from].balance < amount) {
            revert InsufficientTokenBalance();
        }
        // to balance can never overflow because there is a cap on minting
        unchecked {
            _balances[id][from].balance -= uint64(amount);
            _balances[id][to].balance += uint64(amount);
        }

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {
        if (ids.length != amounts.length) revert ArrayLengthMismatch();
        if (to == address(0)) revert TransferToZeroAddress();

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if (_balances[id][from].balance < amount) {
                revert InsufficientTokenBalance();
            }
            // to balance can never overflow because there is a cap on minting
            unchecked {
                _balances[id][from].balance -= uint64(amount);
                _balances[id][to].balance += uint64(amount);
            }
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * NOTE: In order to save gas fees when there are many transactions nearing the mint limit of a tokenId,
     * we do NOT call `_verifyTokenMintLimit` and instead leave it to the external method to do this check.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _verifyWalletMintLimit(to, id, amount);
        unchecked {
            _tokenData[id].numMinted += uint64(amount);
            _balances[id][to].balance += uint64(amount);
            _balances[id][to].numMinted += uint64(amount);
        }
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (ids.length != amounts.length) revert ArrayLengthMismatch();

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _verifyTokenMintLimit(ids[i], amounts[i]);
            _verifyWalletMintLimit(to, ids[i], amounts[i]);
            // The above verifications will check for potential overflow/underflow as well
            unchecked {
                _tokenData[ids[i]].numMinted += uint64(amounts[i]);
                _balances[ids[i]][to].balance += uint64(amounts[i]);
                _balances[ids[i]][to].numMinted += uint64(amounts[i]);
            }
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) revert BurnFromZeroAddress();
        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        uint256 fromBalance = _balances[id][from].balance;
        if (fromBalance < amount) revert InsufficientTokenBalance();
        unchecked {
            _balances[id][from].numBurned += uint64(amount);
            _balances[id][from].balance = uint64(fromBalance - amount);
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal virtual {
        if (from == address(0)) revert BurnFromZeroAddress();
        if (ids.length != amounts.length) revert ArrayLengthMismatch();

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from].balance;
            if (fromBalance < amount) revert InsufficientTokenBalance();
            unchecked {
                _balances[id][from].numBurned += uint64(amount);
                _balances[id][from].balance = uint64(fromBalance - amount);
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if (owner == operator) revert ApprovalToCurrentOwner();
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert TransferToNonERC721ReceiverImplementer();
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert TransferToNonERC721ReceiverImplementer();
            }
        }
    }

    /**
     * @dev helper method to turn a uint256 variable into a 1-length array we can pass into uint256[] variables
     */
    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}