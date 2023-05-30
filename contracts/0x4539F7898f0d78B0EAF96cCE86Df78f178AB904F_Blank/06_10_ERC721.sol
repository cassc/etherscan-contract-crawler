// SPDX-License-Identifier: MIT
// ERC721 Contract
// Creator: Blank Studio
// Based on ERC721A by Chiru Labs

pragma solidity 0.8.14;

import '../interfaces/IERC721A.sol';

/**
 * @dev ERC721 token receiver interface.
 */
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas.
 *
 * - Each mint is indivitual (no batch mint)
 * - Any given address can only mint once
 * - Tokens are sequentially minted starting at 0
 * - Tokens are not burnable
 */
abstract contract ERC721 is IERC721A {
    // last 12 bits (Where the total balance including Gen2 should fit)
    uint256 private constant BALANCE_BITMASK = 0xfff;

    // 13th bit that will be active if the address already minted
    uint256 private constant ALREADY_MINTED_BITMASK = 0x1000;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    // Metadata Base URI
    string internal _baseURI;

    // Mapping from token ID to owner's address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to balance
    // Bits Layout:
    // - [0..12]    `balance`
    // - [13]       `alreadyMinted`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     */
    function totalSupply() public view override returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BALANCE_BITMASK;
    }

    /**
     * @dev Returns true if an address has already minted
     */
    function hasMinted(address owner) public view returns (bool) {
        return (_packedAddressData[owner] & ALREADY_MINTED_BITMASK) > 0;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        if (to == _owners[tokenId]) revert ApprovalToCurrentOwner();

        if (msg.sender != _owners[tokenId])
            if (!isApprovedForAll(_owners[tokenId], msg.sender)) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
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
     * @dev See https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view virtual returns (string memory) {
        return string(abi.encodePacked(_baseURI, "contract.json"));
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory)
    {
        return string(abi.encodePacked(_baseURI, _toString(tokenId), ".json"));
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
        interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
        interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
        interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }


    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentIndex; // If within bounds
    }

    /**
     * @dev Equivalent to `_safeMint(to, '')`.
     */
    function _safeMint(address to) internal {
        _safeMint(to, '');
    }

    /**
     * @dev Safely mints 1 token and transfers it to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        bytes memory _data
    ) internal {
        if (to == address(0)) revert MintToZeroAddress();

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - balance++
            // - alreadyMinted = true
            _packedAddressData[to] = (_packedAddressData[to] + 1) | ALREADY_MINTED_BITMASK;

            // Updates:
            // - `address` to the owner.
            _owners[_currentIndex] = to;

            if (to.code.length != 0) {
                emit Transfer(address(0), to, _currentIndex);
                if (!_checkContractOnERC721Received(address(0), to, _currentIndex++, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            } else {
                emit Transfer(address(0), to, _currentIndex++);
            }
        }
    }

    /**
     * @dev Mints 1 token and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to) internal {
        if (to == address(0)) revert MintToZeroAddress();

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
        // Updates:
        // - balance++
        // - alreadyMinted = true
        _packedAddressData[to] = (_packedAddressData[to] + 1) | ALREADY_MINTED_BITMASK;

        // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `nextInitialized` to `quantity == 1`.
            _owners[_currentIndex] = to;

            emit Transfer(address(0), to, _currentIndex++);
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
        if (_owners[tokenId] != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        if (
            msg.sender != from &&
            !isApprovedForAll(from, msg.sender) &&
            getApproved(tokenId) != msg.sender
        ) revert TransferCallerNotOwnerNorApproved();

        // Clear approvals from the previous owner.
        delete _tokenApprovals[tokenId];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            _packedAddressData[from]--; // Updates: `balance -= 1`.
            _packedAddressData[to]--; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `nextInitialized` to `true`.
            _owners[tokenId] = to;
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
        // The maximum value of a uint256 contains 78 digits (1 byte per digit),
        // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
        // We will need 1 32-byte word to store the length,
        // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
        // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

        // Cache the end of the memory to calculate the length later.
            let end := ptr

        // We write the string from the rightmost digit to the leftmost digit.
        // The following is essentially a do-while loop that also handles the zero case.
        // Costs a bit more than early returning for the zero case,
        // but cheaper in terms of deployment and overall runtime costs.
            for {
            // Initialize and perform the first pass without check.
                let temp := value
            // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
            // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
            // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } { // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
        // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
        // Store the length.
            mstore(ptr, length)
        }
    }
}