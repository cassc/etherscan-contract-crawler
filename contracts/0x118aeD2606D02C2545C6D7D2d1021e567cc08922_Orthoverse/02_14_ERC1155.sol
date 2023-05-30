// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";
import "./Strings.sol";
//
import "hardhat/console.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;
    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => uint256) public tokenCastleLevel;
    // Track revealed tokend Ids
    mapping(uint256 => bool) public revealedTokenIds;
    uint256 public constant REVEALED_TOKENS_LIMIT = 10000;
    uint256 public revealedTokensCounter = 0;
    string private _voidURI;
    bool private _killedMigrator = false;

    // ORTH NFT price, just over 1$ (ETH @ 3100$)
    // !! Prices for Ethereum, for Polygon use: 0.6, 11.5, 1.45
    uint256 public constant REVEAL_PRICE = 0.0004 ether;
    uint256 public constant CASTLE_BASE_PRICE = 0.008 ether;
    uint256 public constant FLIP_REALM_PRICE = 0.001 ether;

    address public W0 = 0x2830B5a3b5242BC2c64C390594ED971E7deD47D2;
    address public W1 = 0x2cdE3C309EF95411f78b338A7de85c4454316208;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(
        string memory uri_,
        address W0_,
        address W1_
    ) {
        _setURI(uri_);
        _setVoidURI(uri_);
        W0 = W0_;
        W1 = W1_;
    }

    /// @notice Public function to retrieve the contract description for OpenSea
    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked(_uri, "contract.json"));
    }

    /**
     * @dev Create the NFT by emitting the event and setting the token ID to the
     * sender's address.
     */
    function reveal() external payable {
        require(
            revealedTokensCounter < REVEALED_TOKENS_LIMIT,
            "We're revealed out!"
        );
        require(msg.value >= REVEAL_PRICE, "Please send 0.0004 ETH");

        address tokenOwner = msg.sender;

        uint256 tokenId = uint256(uint160(tokenOwner));
        require(_balances[tokenId][tokenOwner] == 0, "NFT already revealed");

        _balances[tokenId][tokenOwner] = 1;
        revealedTokensCounter++;
        revealedTokenIds[tokenId] = true;

        address operator = _msgSender();
        emit TransferSingle(operator, address(0), tokenOwner, tokenId, 1);
    }

    /**
     * @dev Make the gift of Orthoverse and spread the joy around you.
     */
    function gift(address account) external payable {
        require(account != address(0), "No gift for 0x0");
        require(
            revealedTokensCounter < REVEALED_TOKENS_LIMIT,
            "We're revealed out!"
        );

        if (msg.sender != W0 && msg.sender != W1) {
            require(msg.value >= REVEAL_PRICE, "Gift: Please send 0.0004 ETH");
        }
        address tokenOwner = account;

        uint256 tokenId = uint256(uint160(tokenOwner));
        require(_balances[tokenId][tokenOwner] == 0, "NFT already revealed");

        _balances[tokenId][tokenOwner] = 1;
        revealedTokensCounter++;
        revealedTokenIds[tokenId] = true;

        address operator = _msgSender();
        emit TransferSingle(operator, address(0), tokenOwner, tokenId, 1);
    }

    // Required after "Panic at the Orthoverse V1"
    function _migrator(
        address[] calldata from_,
        address[] calldata to_,
        uint256[] calldata tokenId_,
        uint256[] calldata level_
    ) internal {
        require(!_killedMigrator, "killed!");
        for (uint256 i = 0; i < from_.length; i++) {
            tokenCastleLevel[tokenId_[i]] = level_[i];
            revealedTokenIds[tokenId_[i]] = true;
            address operator = from_[i];
            if (from_[i] == address(0)) {
                // we have a mint
                operator = to_[i];
                revealedTokensCounter++;
                // but if the tokenId doesn't equal the to_ address, we have to set balance of tokenId address to 2
                // because it's a panic bug mint. This will cause problems if the tokenId is bigger than a uint160()
                // except it's easier to do this in the calldata list than in a smart contract so we check and edit that.
            } else {
                // we have a transfer
                _balances[tokenId_[i]][from_[i]]++;
            }
            _balances[tokenId_[i]][to_[i]]++;
            emit TransferSingle(operator, from_[i], to_[i], tokenId_[i], 1);
        }
    }

    // Never go back...
    function _killMigrator() internal {
        _killedMigrator = true;
    }

    /**
     * @dev Returns 0 if the token has not been revealed
     */
    function isRevealed() external view returns (uint256) {
        address account = msg.sender;
        uint256 id = uint256(uint160(account));
        return _balances[id][account];
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

    /// @notice  Returns the metadata URI for tokenId
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // Return the void URI if the token is not revealed
        string memory tokenURI = revealedTokenIds[tokenId] ? _uri : _voidURI;

        return
            string(
                abi.encodePacked(
                    tokenURI,
                    Strings.toHexString(tokenId),
                    "-",
                    Strings.toString(tokenCastleLevel[tokenId]),
                    ".json"
                )
            );
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be 0x0.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(account != address(0), "balance query for 0x0");
        if (id == uint256(uint160(account)) && (_balances[id][account] == 0)) {
            return 1;
        } else {
            return _balances[id][account] % 2;
        }
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "accounts and ids length mismatch"
        );

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

    function flipRealm(uint256 tokenId_) external payable {
        require(
            _balances[tokenId_][msg.sender] % 2 == 1,
            "only owner of revealed token can flip"
        );

        if (msg.sender != W0 && msg.sender != W1) {
            require(msg.value >= FLIP_REALM_PRICE, "Not enough ETH");
        }

        if (tokenCastleLevel[tokenId_] > 7) {
            tokenCastleLevel[tokenId_] = tokenCastleLevel[tokenId_] - 8;
        } else {
            tokenCastleLevel[tokenId_] = tokenCastleLevel[tokenId_] + 8;
        }
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
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "must be owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "must be owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be 0x0.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        // we just ignore amount, because it's always one
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "transfer to 0x0");

        address operator = _msgSender();

        if (id != uint256(uint160(from))) {
            require(_balances[id][from] % 2 == 1, "Not owner!");
        }

        if (_balances[id][from] == 0) {
            // this actually makes the NFT
            _balances[id][from] = 1;

            if (revealedTokensCounter < REVEALED_TOKENS_LIMIT) {
                revealedTokenIds[id] = true;
                revealedTokensCounter++;
            }
            emit TransferSingle(operator, address(0), from, id, 1);
        }
        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        uint256 fromBalance = _balances[id][from];

        require(fromBalance % 2 == 1, "insufficient balance for transfer");

        unchecked {
            _balances[id][from] += 1;
        }

        _balances[id][to] += 1;

        emit TransferSingle(operator, from, to, id, 1);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, 1, data);
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
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "ids and amounts length mismatch"
        );
        require(to != address(0), "transfer to 0x0");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            if (id != uint256(uint160(from))) {
                require(_balances[id][from] % 2 == 1, "Not owner!");
            }

            if (_balances[id][from] == 0) {
                // this actually makes the NFT
                _balances[id][from] = 1;

                if (revealedTokensCounter < REVEALED_TOKENS_LIMIT) {
                    revealedTokenIds[id] = true;
                    revealedTokensCounter++;
                }
            }
            uint256 fromBalance = _balances[id][from];
            require(
                (fromBalance % 2 == 1),
                "insufficient balance for transfer batch"
            );

            unchecked {
                _balances[id][from] = fromBalance + 1;
            }
            _balances[id][to] += 1;
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
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    function _setVoidURI(string memory newVoidURI) internal virtual {
        _voidURI = newVoidURI;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be 0x0.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "mint to 0x0");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][to] += amount;
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
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "mint to 0x0");
        require(
            ids.length == amounts.length,
            "ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
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
     * - `from` cannot be 0x0.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "burn from 0x0");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
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
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "burn from 0x0");
        require(
            ids.length == amounts.length,
            "ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
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
        require(owner != operator, "setting approval status for self");
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
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
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
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("transfer to non ERC1155Receiver implementer");
            }
        }
    }

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