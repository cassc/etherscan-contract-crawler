// SPDX-License-Identifier: MIT
// Fork of ERC721A created by Chiru Labs
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

error ApproveToCaller();
error ApprovalToCurrentOwner();
error CallerNotOwnerNorApproved(string method);
error MethodReceivedZeroAddress(string method);
error MintZeroQuantity();
error QueryForNonexistentToken(string method);
error TokenQueryProducedVariant();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();

/**
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3...)
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * Assumes that the maximum token tokenId cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, Ownable, Pausable {
    using Address for address;
    using Strings for uint256;


    uint32 public constant MINT_BATCH_SIZE = 8;

    uint32 public constant STATE_BURNED = 1;
    uint32 public constant STATE_MINTED = 2;
    uint32 public constant STATE_TRANSFERRED = 3;


    struct Approvals {
        // Owner Address => [Operator Address => Approved if true, otherwise false]
        mapping(address => mapping(address => bool)) operators;

        // Token Id => Approved Address
        mapping(uint256 => address) tokens;
    }

    struct Owner {
        uint64 balance;
        uint64 burned;
        uint64 minted;
        uint64 misc;
    }

    struct Token {
        address owner;
        uint32 state;
        uint64 updatedAt;
    }


    string internal _baseURI;

    uint256 private _burned;

    string internal _name;

    uint256 private _nextId;

    string internal _symbol;


    // Namespaced Approval Data
    Approvals private _approvals;

    // Owner Address => Owner Data
    mapping(address => Owner) private _owners;

    // Token Id => Token Data
    mapping(uint256 => Token) private _tokens;

    mapping(uint256 => string) private _tokenURI;


    constructor(string memory name_, string memory symbol_) Ownable() Pausable() {
        _name = name_;
        _nextId = _startTokenId();
        _symbol = symbol_;
    }


    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token tokenId to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address from, address to, uint256 tokenId) private {
        _approvals.tokens[tokenId] = to;

        emit Approval(from, to, tokenId);
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are
     * about to be transferred. This includes minting. And also called before
     * burning one token.
     *
     * startTokenId - the first token tokenId to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}

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
    function _burn(uint256 tokenId, bool verifyApproved) internal virtual whenNotPaused {
        Token memory token = _token(tokenId);

        if (verifyApproved && !_isApprovedOrOwner(tokenId, _msgSender())) {
            revert CallerNotOwnerNorApproved({ method: '_burn' });
        }

        _beforeTokenTransfers(token.owner, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(token.owner, address(0), tokenId);

        // Update next 'tokenId' if owned by 'from'
        _setDeferredOwnership(tokenId, token);

        // Underflow of the sender's balance is impossible because we check for
        // token above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            Owner storage owner = _owners[token.owner];
            owner.balance -= 1;
            owner.burned += 1;

            _burned += 1;
        }

        // Keep track of last owner
        _tokens[tokenId] = Token({
            owner: token.owner,
            state: STATE_BURNED,
            updatedAt: uint64(block.timestamp)
        });

        emit Transfer(token.owner, address(0), tokenId);

        _afterTokenTransfers(token.owner, address(0), tokenId, 1);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token tokenId
     * @param to target address that will receive the tokens
     * @param tokenId uint256 tokenId of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        }
        catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            }

            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return (tokenId + 1) > _startTokenId() && tokenId < _nextId && _tokens[tokenId].state != STATE_BURNED;
    }

    function _isApprovedOrOwner(uint256 tokenId, address sender) internal view returns (bool) {
        address owner = ownerOf(tokenId);

        return sender == owner || getApproved(tokenId) == sender || isApprovedForAll(owner, sender);
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
    function _mint(address to, uint256 quantity, bytes memory data, bool safe) internal whenNotPaused {
        uint256 start = _nextId;

        if (to == address(0)) {
            revert MethodReceivedZeroAddress({ method: '_mint' });
        }

        if (quantity == 0) {
            revert MintZeroQuantity();
        }

        _beforeTokenTransfers(address(0), to, start, quantity);

        // Overflows are incredibly unrealistic.
        // balance or minted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // tokenId overflows if _nextId + quantity > 1.2e77 (2**256) - 1
        unchecked {
            Owner storage owner = _owners[to];
            owner.balance += uint64(quantity);
            owner.minted += uint64(quantity);

            uint256 batches = quantity / MINT_BATCH_SIZE;

            if (quantity % MINT_BATCH_SIZE != 0) {
                batches += 1;
            }

            for (uint256 batch = 0; batch < batches; batch++) {
                _tokens[start + (MINT_BATCH_SIZE * batch)] = Token({
                    owner: to,
                    state: STATE_MINTED,
                    updatedAt: uint64(block.timestamp)
                });
            }

            uint256 current = start;
            uint256 last = current + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, current);

                    if (!_checkContractOnERC721Received(address(0), to, current++, data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (current != last);

                // Reentrancy protection
                if (_nextId != start) {
                    revert();
                }
            }
            else {
                do {
                    emit Transfer(address(0), to, current++);
                } while (current != last);
            }

            _nextId = current;
        }

        _afterTokenTransfers(address(0), to, start, quantity);
    }

    function _owner(address owner) internal view returns (Owner memory) {
        return _owners[owner];
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 quantity, bytes memory data) internal {
        _mint(to, quantity, data, true);
    }

    /**
     * If the token slot of tokenId+1 is not explicitly set, that means the
     * transfer initiator owns it. Set the slot of tokenId+1 explicitly in
     * storage to maintain correctness for ownerOf(tokenId+1) calls.
     */
    function _setDeferredOwnership(uint256 tokenId, Token memory token) private {
        uint256 next = tokenId + 1;

        if (_exists(next) && _tokens[next].owner == address(0)) {
            _tokens[next] = token;
        }
    }

    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _token(uint256 tokenId) internal view returns (Token memory) {
        if (!_exists(tokenId)) {
            revert QueryForNonexistentToken({ method: '_token' });
        }

        unchecked {
            uint256 batch = MINT_BATCH_SIZE + 1;
            uint256 n = _startTokenId();

            if (tokenId > batch) {
                n = tokenId - batch;
            }

            for (uint256 i = tokenId; i > n; i--) {
                Token memory token = _tokens[i];

                if (token.owner != address(0)) {
                    return token;
                }
            }
        }

        revert TokenQueryProducedVariant();
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
    function _transfer(address from, address to, uint256 tokenId) private whenNotPaused {
        Token memory token = _token(tokenId);

        if (to == address(0)) {
            revert MethodReceivedZeroAddress({ method: '_transfer' });
        }

        if (token.owner != from) {
            revert TransferFromIncorrectOwner();
        }

        if (!_isApprovedOrOwner(tokenId, _msgSender())) {
            revert CallerNotOwnerNorApproved({ method: '_transfer' });
        }

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(token.owner, address(0), tokenId);

        // Update next tokenId if owned by 'from'
        _setDeferredOwnership(tokenId, token);

        // Underflow of the sender's balance is impossible because we check for
        // token above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _owners[from].balance -= 1;
            _owners[to].balance += 1;
        }

        _tokens[tokenId] = Token({
            owner: to,
            state: uint32(STATE_TRANSFERRED),
            updatedAt: uint64(block.timestamp)
        });

        emit Transfer(from, to, tokenId);

        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev See {IERC721-approve}
     */
    function approve(address to, uint256 tokenId) override public {
        address owner = ownerOf(tokenId);
        address sender = _msgSender();

        if (to == owner) {
            revert ApprovalToCurrentOwner();
        }

        if (sender != owner && !isApprovedForAll(owner, sender)) {
            revert CallerNotOwnerNorApproved({ method: 'approve' });
        }

        _approve(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-balanceOf}
     */
    function balanceOf(address owner) override public view returns (uint256) {
        if (owner == address(0)) {
            revert MethodReceivedZeroAddress({ method: 'balanceOf' });
        }

        return uint256(_owners[owner].balance);
    }

    /**
     * @dev See {IERC721-getApproved}
     */
    function getApproved(uint256 tokenId) override public view returns (address) {
        if (!_exists(tokenId)) {
            revert QueryForNonexistentToken({ method: 'getApproved' });
        }

        return _approvals.tokens[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}
     */
    function isApprovedForAll(address owner, address operator) override public view virtual returns (bool) {
        return _approvals.operators[owner][operator];
    }

    function name() override(IERC721Metadata) public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721-ownerOf}
     */
    function ownerOf(uint256 tokenId) override public view returns (address) {
        return _token(tokenId).owner;
    }

    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) override public virtual {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) override public virtual {
        _transfer(from, to, tokenId);

        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev See {IERC721-setApprovalForAll}
     */
    function setApprovalForAll(address operator, bool approved) override public virtual {
        address sender = _msgSender();

        if (operator == sender) {
            revert ApproveToCaller();
        }

        _approvals.operators[sender][operator] = approved;

        emit ApprovalForAll(sender, operator, approved);
    }

    function setBaseURI(string memory uri) public onlyOwner virtual {
        _baseURI = uri;
    }


    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner virtual {
        if (!_exists(tokenId)) {
            revert QueryForNonexistentToken({ method: 'setTokenURI' });
        }

        _tokenURI[tokenId] = uri;
    }

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) override(ERC165, IERC165) public view virtual returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function symbol() override(IERC721Metadata) public view virtual returns (string memory) {
        return _symbol;
    }

    function tokensOf(address owner, uint256 cursor, uint256 size) external view returns (uint256[] memory, uint256) {
        uint256 balance = balanceOf(owner);
        uint256 max = _nextId;

        if (balance == 0) {
            return (new uint256[](0), cursor);
        }

        unchecked {
            if (cursor < _startTokenId()) {
                cursor = _startTokenId();
            }

            uint256 length = size;

            if (length > max - cursor) {
                length = max - cursor;
            }

            uint256[] memory ids = new uint256[](balance);

            // Cursor token may not be 'initialized' due to ERC721A design, use
            // normal token fetching function to find owner of token.
            Token memory token = _token(cursor);
            address current;

            if (token.state != STATE_BURNED) {
                current = token.owner;
            }

            uint256 j;

            for (uint256 i = cursor; i != length && j != balance; i++) {
                token = _tokens[i];

                if (token.owner == address(0) || token.state == STATE_BURNED) {
                    continue;
                }

                current = token.owner;

                if (current == owner) {
                    ids[j++] = i;
                }
            }

            // Downsize the array to fit
            assembly {
                mstore(ids, j)
            }

            return (ids, (cursor + size));
        }
    }

    function tokenURI(uint256 tokenId) override(IERC721Metadata) public view virtual returns (string memory) {
        if (!_exists(tokenId)) {
            revert QueryForNonexistentToken({ method: 'tokenURI' });
        }

        string memory base = _baseURI;
        string memory token = _tokenURI[tokenId];

        if (bytes(token).length == 0) {
            token = tokenId.toString();
        }

        if (bytes(base).length != 0) {
            return string(abi.encodePacked(base, token));
        }

        return token;
    }

    function totalBurned() public view returns (uint256) {
        return _burned;
    }

    function totalMinted() public view returns (uint256) {
        unchecked {
            return _nextId - _startTokenId();
        }
    }

    function totalSupply() public view returns (uint256) {
        unchecked {
            return _nextId - _burned - _startTokenId();
        }
    }

    /**
     * @dev See {IERC721-transferFrom}
     */
    function transferFrom(address from, address to, uint256 tokenId) override public virtual {
        safeTransferFrom(from, to, tokenId);
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}