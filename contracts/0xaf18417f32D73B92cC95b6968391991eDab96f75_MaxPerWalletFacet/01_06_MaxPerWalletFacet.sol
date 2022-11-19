// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {AppStorage, Modifiers} from "../libraries/LibAppStorage.sol";
import "../libraries/LibERC721.sol";

contract MaxPerWalletFacet is Modifiers {
    /// Set max allowed per transaction
    function setMaxPerWallet(uint256 maxPerWallet) external onlyEditor {
        s._maxPerWallet = maxPerWallet;
    }

    /// Set to enable and disable public max per wallet paid to mint
    function setMaxPerWalletPaidOpen(bool newValue) external onlyEditor {
        s.maxPerWalletPaidOpen = newValue;
    }

    /// Set to enable and disable public max per wallet free to mint
    function setMaxPerWalletFreeOpen(bool newValue) external onlyEditor {
        s.maxPerWalletFreeOpen = newValue;
    }

    /// Minting for max per wallet tokens paid
    function mintMaxPerWalletPaid(address targetAddress, uint16 quantity) external payable {
        /// Revert if public max per wallet sale is not open
        require(s.maxPerWalletPaidOpen, "Public max per wallet paid not open");
        /// Revert if over max allowed per wallet
        require(s._addressData[targetAddress].balance < s._maxPerWallet, "Max per wallet met");
        /// Revert if incorrect amount sent
        require(msg.value == s.priceWEI * quantity, "Incorrect value sent");
        /// Revert if outside sale limit
        require((s._currentIndex - 1) + quantity <= s.saleLimit, "Quanity more than available");

        _mint(targetAddress, quantity);
    }

    /// Minting for max per wallet  tokens paid
    function mintMaxPerWalletFree(address targetAddress, uint16 quantity) external payable {
        /// Revert if public max per wallet sale is not open
        require(s.maxPerWalletFreeOpen, "Public max per wallet free not open");
        /// Revert if over max allowed per wallet
        require(s._addressData[targetAddress].balance < s._maxPerWallet, "Max per wallet met");
        /// Revert if outside sale limit
        require((s._currentIndex - 1) + quantity <= s.saleLimit, "Quanity more than available");

        _mint(targetAddress, quantity);
    }

    /// Returns max allowed per transaction
    function getMaxPerWallet() external view returns (uint256) {
        return s._maxPerWallet;
    }

    /// Returns if public max per wallet paid mint is open
    function maxPerWalletPaidOpen() external view returns (bool) {
        return s.maxPerWalletPaidOpen;
    }

    /// Returns if public max per wallet mint free is open
    function maxPerWalletFreeOpen() external view returns (bool) {
        return s.maxPerWalletFreeOpen;
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
        uint256 _startingId = s._currentIndex;
        require(to > address(0), "Zero address");
        require(quantity > 0, "Quantity zero");

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

            do {
                emit LibERC721.Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex != end);

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
}