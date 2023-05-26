// SPDX-License-Identifier: UNLICENSE
// Creator: 0xYeety; Based Pixel Labs/Yeety Labs; 1 yeet = 1 yeet; 1 cope = 1 cope
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721Storage is Ownable {
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

    uint256 private currentIndex = 0;

    uint256 internal immutable maxBatchSize;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Base URI
    string private _baseURI;
    bool revealed = false;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) private _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;


    uint256 private mintPrice;
    uint256 private maxPossibleSupply;
    uint256 private maxAllowedMints;
    address private immutable currency;
    address private immutable wrappedNativeCoinAddress;

    /**
     * @dev
     * `maxBatchSize` refers to how much a minter can mint at a time.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_,
        uint256 mintPrice_,
        uint256 maxPossibleSupply_,
        address currency_,
        address wrappedNativeCoinAddress_
    ) {
        require(maxBatchSize_ > 0, "b");
        _name = name_;
        _symbol = symbol_;
        maxBatchSize = maxBatchSize_;
        mintPrice = mintPrice_;
        maxPossibleSupply = maxPossibleSupply_;
        currency = currency_;
        wrappedNativeCoinAddress = wrappedNativeCoinAddress_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return currentIndex;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < totalSupply(), "g");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < balanceOf(owner), "b");
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < numMintedSoFar; i++) {
            TokenOwnership memory ownership = _ownerships[i];
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("u");
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "0");
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        require(owner != address(0), "0");
        return uint256(_addressData[owner].numberMinted);
    }

    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        require(_exists(tokenId), "t");

        uint256 lowestTokenToCheck;
        if (tokenId >= maxBatchSize) {
            lowestTokenToCheck = tokenId - maxBatchSize + 1;
        }

        for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
            TokenOwnership memory ownership = _ownerships[curr];
            if (ownership.addr != address(0)) {
                return ownership;
            }
        }

        revert("o");
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return ownershipOf(tokenId).addr;
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
        require(_exists(tokenId), "z");

        if (revealed) {
            return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, "/", tokenId.toString(), ".json")) : "";
        }
        else {
            return _baseURI;
        }
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) public virtual onlyOwner {
        _baseURI = baseURI_;
    }

    function _revealMetadata() public virtual onlyOwner {
        revealed = true;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address msgSender, address to, uint256 tokenId) public onlyOwner {
        address owner = ownerOf(tokenId);
        require(to != owner, "o");

        require(
            msgSender == owner || isApprovedForAll(owner, msgSender),
            "a"
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "a");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address msgSender, address operator, bool approved) public onlyOwner {
        require(operator != msgSender, "a");

        _operatorApprovals[msgSender][operator] = approved;
        //        emit ApprovalForAll(msgSender, operator, approved);
        ERC721TopLevel(msg.sender).emitApprovalForAll(msgSender, operator, approved);
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
    function transferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        _transfer(msgSender, from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        safeTransferFrom(msgSender, from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public onlyOwner {
        _transfer(msgSender, from, to, tokenId);
        require(
            _checkOnERC721Received(msgSender, from, to, tokenId, _data),
            "z"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address msgSender, address from, address to, uint256 quantity) public onlyOwner {
        _safeMint(msgSender, from, to, quantity, "");
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` cannot be larger than the max batch size.
     *
     * Emits either one or two {Transfer} events, depending on the
     * values of {from} and {to}.
     */
    function _safeMint(
        address msgSender,
        address from,
        address to,
        uint256 quantity,
        bytes memory _data
    ) public onlyOwner {
        uint256 startTokenId = currentIndex;
        require(to != address(0), "0");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), "a");
        require(quantity <= maxBatchSize, "m");

        if (from != address(0)) {
            _beforeTokenTransfers(address(0), from, startTokenId, quantity);
        }
        if (from != to) {
            _beforeTokenTransfers(from, to, startTokenId, quantity);
        }

        AddressData memory addressData = _addressData[to];
        _addressData[to] = AddressData(
            addressData.balance + uint128(quantity),
            addressData.numberMinted + uint128(quantity)
        );
        _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            if (from != address(0)) {
                ERC721TopLevel(msg.sender).emitTransfer(address(0), from, updatedIndex);
            }
            if (from != to) {
                ERC721TopLevel(msg.sender).emitTransfer(from, to, updatedIndex);
            }
            require(
                _checkOnERC721Received(msgSender, address(0), from, updatedIndex, _data) && _checkOnERC721Received(msgSender, from, to, updatedIndex, _data),
                "z"
            );
            updatedIndex++;
        }

        currentIndex = updatedIndex;
        if (from != address(0)) {
            _afterTokenTransfers(address(0), from, startTokenId, quantity);
        }
        if (from != to) {
            _afterTokenTransfers(from, to, startTokenId, quantity);
        }
    }

    function mintFn(
        address msgSender,
        uint _amount,
        address _from,
        address _to,
        uint256 _msgValue
    ) public onlyOwner {
        require(totalSupply() + _amount <= maxPossibleSupply, "m");
        require(_numberMinted(_to) + _amount <= maxBatchSize, "l");

        if (currency == wrappedNativeCoinAddress) {
            if (address(msgSender) != ERC721TopLevel(msg.sender).owner()) {
                require(mintPrice * _amount <= _msgValue, "a");
            }
        }
        else {
            IERC20 _currency = IERC20(currency);
            _currency.transferFrom(msg.sender, address(msg.sender), _amount * mintPrice);
        }

        _safeMint(msgSender, _from, _to, _amount);
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
    function _transferMain(address from, address to, uint256 tokenId, TokenOwnership memory prevOwnership) private {
        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // De-list item if it was previously listed

        _addressData[from].balance -= 1;
        _addressData[to].balance += 1;
        _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId].addr == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerships[nextTokenId] = TokenOwnership(prevOwnership.addr, prevOwnership.startTimestamp);
            }
        }

        ERC721TopLevel(msg.sender).emitTransfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    function _transfer(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (msgSender == prevOwnership.addr ||
        getApproved(tokenId) == msgSender ||
        isApprovedForAll(prevOwnership.addr, msgSender));

        require(isApprovedOrOwner, "a");

        require(prevOwnership.addr == from, "o");
        require(to != address(0), "0");

        _transferMain(from, to, tokenId, prevOwnership);
    }

    /**
     * Called only by the owner's marketplace functions
     */
    //    function transferBySale(
    //        address from,
    //        address to,
    //        uint256 tokenId
    //    ) public onlyOwner {
    //        _transfer(msg.sender, from, to, tokenId);
    //    }
    function transferBySale(
        address from,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _transferMain(from, to, tokenId, prevOwnership);
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
        //        emit Approval(owner, to, tokenId);
        ERC721TopLevel(msg.sender).emitApproval(owner, to, tokenId);
    }

    uint256 public nextOwnerToExplicitlySet = 0;

    /**
     * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
     */
    function _setOwnersExplicit(uint256 quantity) internal {
        uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
        require(quantity > 0, "q");
        uint256 endIndex = oldNextOwnerToSet + quantity - 1;
        if (endIndex > currentIndex - 1) {
            endIndex = currentIndex - 1;
        }
        // We know if the last one in the group exists, all in the group exist, due to serial ordering.
        require(_exists(endIndex), "n");
        for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
            if (_ownerships[i].addr == address(0)) {
                TokenOwnership memory ownership = ownershipOf(i);
                _ownerships[i] = TokenOwnership(ownership.addr, ownership.startTimestamp);
            }
        }
        nextOwnerToExplicitlySet = endIndex + 1;
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
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msgSender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("z");
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
        uint256 startTokenId,
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
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

abstract contract ERC721TopLevel {
    function emitTransfer(address _from, address _to, uint256 _tokenId) public virtual;
    function emitApproval(address _owner, address _approved, uint256 _tokenId) public virtual;
    function emitApprovalForAll(address _owner, address _operator, bool _approved) public virtual;

    //    function isListed(uint256 tokenId) public virtual returns (bool);
    function deList(uint256 tokenId) public virtual;
    function owner() public virtual returns (address);
}