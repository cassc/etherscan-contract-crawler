// SPDX-License-Identifier: MIT
// Creator: Christopher Mikel Shelton

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintZeroQuantity();
error TokenNotClaimable();
error TokenAlreadyExists();
error OwnerIsZeroAddress();
error CallOnlyValidAfterTokenOffset();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard
 *
 * This contract is design to handle the standard ERC721 implementation
 * and a gas optimized batch minting process pioneered by ERC721A.
 * Within the same collection, the first range of tokens may be minted in any order
 * using {_safeClaim} and at the point of the offset, every token after that must
 * be minted sequentially as it implements batch minting using {_safeMint}
 * 
 */
contract ERC721SZNS is Context, ERC165, IERC721, IERC721Metadata {
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

    // ===== Key token split offset between known tokenIds and new collection =====
    uint256 internal immutable _tokenSplitOffset;

    // ===== tokenIds for the latter part of the collection, after offset =====
    uint256 private _nextTokenId;

    uint256 private _tokensClaimed;
    uint256 private _tokensMinted;

    constructor(string memory name_, string memory symbol_, uint256 offset) {
        _name = name_;
        _symbol = symbol_;
        _tokenSplitOffset = offset;
        // the next token id will be the offset plus 1, as it is 1 based indexed
        // i.e. offset is 5864, next token to be minted sequentially is 5865
        _nextTokenId = offset + 1;
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
     * @dev See {IERC721Enumerable-totalSupply}.
     *
     * Number of claimed summer tokens plus number of minted season tokens
     */
    function totalSupply() public view returns (uint256) {
        unchecked {
            return _tokensClaimed + _tokensMinted;
        }
    }

    function tokensClaimed() public view returns (uint256) {
        return _tokensClaimed;
    }

    function tokensMinted() public view returns (uint256) {
        return _tokensMinted;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf} or {ERC721A-ownerOf}
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner;

        if (tokenId > _tokenSplitOffset) {
            unchecked {
                // 'tokenId + 1' and '>' is cheaper than doing '>=' without '+1'
                if (tokenId + 1 > _nextTokenId) revert OwnerQueryForNonexistentToken();

                for (uint256 curr = tokenId;; curr--) {
                    owner = _owners[curr];
                    if (owner != address(0)) {
                        return owner;
                    }
                }
            }

            revert OwnerQueryForNonexistentToken();
        }

        owner = _owners[tokenId];

        if (owner == address(0)) revert OwnerIsZeroAddress();
        
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
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
    function approve(address to, uint256 tokenId) public virtual {
        address owner = ERC721SZNS.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) revert TransferToNonERC721ReceiverImplementer();
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
        if (quantity == 0) revert MintZeroQuantity();

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if currentIndex + quantity > 1.56e77 (2**256) - 1
        unchecked {
            _balances[to] += quantity;
            _owners[_nextTokenId] = to;

            uint256 updatedIndex = _nextTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                updatedIndex++;
            }

            _tokensMinted += quantity;
            _nextTokenId = updatedIndex;
        }
    }

    function _claim(address to, uint256 tokenId) internal {
        if (tokenId > _tokenSplitOffset) revert TokenNotClaimable();
        if (_exists(tokenId)) revert TokenAlreadyExists();

        unchecked {
            _balances[to]++;
            _owners[tokenId] = to;

            _tokensClaimed++;
            
            emit Transfer(address(0), to, tokenId);
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
    function _transfer(address from, address to, uint256 tokenId) private {
        address prevOwner = ERC721SZNS.ownerOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwner ||
            isApprovedForAll(prevOwner, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

        if (prevOwner != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwner);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _balances[from]--;
            _balances[to]++;
            _owners[tokenId] = to;

            // this only applies to the second part of the collection
            if (tokenId > _tokenSplitOffset) {
                // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
                // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
                uint256 nextTokenId = tokenId + 1;

                if (_owners[nextTokenId] == address(0)) {
                    if (_exists(nextTokenId)) {
                        _owners[nextTokenId] = prevOwner;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens will exist once they are claimed within the first part of the collection
     * or when they are {_mint}
     *
     * @dev If token is greater than the collection offset, it uses {ERC721A-_exist}
     * else it uses {ERC721-_exist}
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        if (tokenId > _tokenSplitOffset) return tokenId < _nextTokenId;

        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId, address owner) internal virtual {
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
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
                    revert TransferToNonERC721ReceiverImplementer();
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