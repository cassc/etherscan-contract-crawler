// SPDX-License-Identifier: MIT
///Adapted from Azuki's ERC721A https://github.com/chiru-labs/ERC721A as of 4/28/22
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import "../libraries/LibERC721.sol";

import {AddressData, AppStorage, TokenOwnership, Modifiers} from "../libraries/LibAppStorage.sol";

error OwnerQueryForNonexistentToken();
error TransferToNonERC721ReceiverImplementer();

contract MintingFacet is IERC721, Modifiers {
    using Address for address;
    using Strings for uint256;

    /// Main purchase function
    function purchase(address targetAddress, uint256 quantity) external payable {
        /// Revert if sale is not open
        require(s.publicMintOpen, "Sale is not open");

        /// Revert if quantity more than allowed
        require(quantity < s._maxAllowed, "Quantity more than allowed per transaction");

        /// Revert if outside sale limit
        require(totalMinted() + quantity < s.saleLimit, "Quantity more than remaining");

        /// Revert if incorrect amount sent
        require(msg.value == s.priceWEI * quantity, "Incorrect amount sent");

        _mint(targetAddress, quantity, "", true);
    }

    /// Set an address as a contract editor
    function setEditor(address editor) external onlyOwner {
        s._editors[editor] = true;
    }

    /// Set baseURI for metadata
    function setBaseURI(string memory uri) external onlyEditor {
        s.baseURI = uri;
    }

    /// Set price for the token
    function setPrice(uint256 price) external onlyEditor {
        s.priceWEI = price;
    }

    /// Set mintStarted to enable and disable the general sale
    function setPublicMintOpen(bool newPublicMintOpenValue) external onlyEditor {
        s.publicMintOpen = newPublicMintOpenValue;
    }

    /// Set royaltyTarget for the address to receive royalties
    /// This is assuming marketplaces will adopt IERC2981
    function setRoyaltyTarget(address targetAddress) external onlyEditor {
        require(address(targetAddress) != address(0), "Address is Zero");
        s._royaltyTarget = targetAddress;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(to != owner, "Approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Approval denied");

        _approve(to, tokenId, owner);
    }

    /**
     * @dev Burns `tokenId`.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external virtual {
        _burn(tokenId, true);
    }

    //Bulk burns if address provided owns token. Only callable by set editor including external contracts.
    function bulkBurn(uint256[] memory burnTokens, address tokenOwner) external onlyEditor {
        for (uint256 i = 0; i < burnTokens.length; i++) {
            bool isApproved = _ownershipOf(burnTokens[i]).addr == tokenOwner;
            require(isApproved, "Token not owned by address");
            _burn(burnTokens[i], false);
        }
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "Approve to caller");
        s._operatorApprovals[msg.sender][operator] = approved;
        emit LibERC721.ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        string memory baseURI = s.baseURI;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Burned tokens are calculated here, use totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256) {
        // Counter underflow is impossible as __burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return s._currentIndex - s._burnCounter - _startTokenId();
        }
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "Address is Zero");
        return uint256(s._addressData[owner].balance);
    }

    /// Returns whether `tokenId` exists.
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function numberMinted(address owner) external view returns (uint256) {
        return uint256(s._addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function numberBurned(address owner) external view returns (uint256) {
        return uint256(s._addressData[owner].numberBurned);
    }

    /// Return the universal name of the NFT
    function name() external view returns (string memory) {
        return s.name;
    }

    /// Returns price in WEI
    function priceWEI() external view returns (uint256) {
        return s.priceWEI;
    }

    /// Returns if public mint is open
    function publicMintOpen() external view returns (bool) {
        return s.publicMintOpen;
    }

    /// Royalty info per IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        _tokenId; // to silence unused variable warnings
        return (s._royaltyTarget, (_salePrice * 15) / 200); /// To get 7.5%
    }

    /// Returns the limit of the sale
    function saleLimit() external view returns (uint256) {
        return s.saleLimit;
    }

    /// An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory) {
        return s.symbol;
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Token does not exist");
        return s._tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return s._operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() public view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return s._currentIndex - _startTokenId();
        }
    }

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
    function _burn(uint256 tokenId, bool approvalCheck) internal {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (msg.sender == from || isApprovedForAll(from, msg.sender) || getApproved(tokenId) == msg.sender);

            require(isApprovedOrOwner, "Transfer caller not owner nor approved");
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = s._addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = s._ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = s._ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != s._currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit LibERC721.Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as __burnCounter cannot be exceed _currentIndex times.
        unchecked {
            s._burnCounter++;
        }
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
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 _startingId = s._currentIndex;
        require(to != address(0), "Address is zero");
        require(quantity != 0, "Quantity is zero");

        _beforeTokenTransfers(address(0), to, _startingId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            s._addressData[to].balance += uint64(quantity);
            s._addressData[to].numberMinted += uint64(quantity);

            s._ownerships[_startingId].addr = to;
            s._ownerships[_startingId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = _startingId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit LibERC721.Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (s._currentIndex != _startingId) revert();
            } else {
                do {
                    emit LibERC721.Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            s._currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, _startingId, quantity);
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * _startTokenId - the first token id to be transferred
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
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 _startingId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * _startingId - the first token id to be transferred
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
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 _startingId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < s._currentIndex && !s._ownerships[tokenId].burned;
    }

    /// Sets the first token id
    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < s._currentIndex) {
                TokenOwnership memory ownership = s._ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = s._ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
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

        require(prevOwnership.addr == from, "Transfer from incorrect owner");

        bool isApprovedOrOwner = (msg.sender == from || isApprovedForAll(from, msg.sender) || getApproved(tokenId) == msg.sender);

        require(isApprovedOrOwner, "Transfer caller not owner nor approved");
        require(to != address(0), "Address is zero");

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            s._addressData[from].balance -= 1;
            s._addressData[to].balance += 1;

            TokenOwnership storage currSlot = s._ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = s._ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != s._currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit LibERC721.Transfer(from, to, tokenId);
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
        s._tokenApprovals[tokenId] = to;
        emit LibERC721.Approval(owner, to, tokenId);
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
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
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
}