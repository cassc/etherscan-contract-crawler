// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {AppStorage, Modifiers} from "../libraries/LibAppStorage.sol";
import "../libraries/LibERC721.sol";

// import "hardhat/console.sol";

contract VerifiedMintFacet is Modifiers {
    using ECDSA for bytes32;

    /// Mints one token free
    function mintOneFree(
        address targetAddress,
        uint32 uniqueNumber,
        bytes memory signature
    ) external payable {
        /// Revert if allow list sale is not open
        require(s.allowListFreeOpen, "Allow list not open");
        /// Revert if over max allowed per wallet
        require(s._addressData[targetAddress].balance < s._maxPerWallet, "Max per wallet met");
        /// Revert if message already used
        require(!s._usedVerifiedMessages[uniqueNumber], "Verified message is used");
        /// Revert if outside sale limit
        require((s._currentIndex - 1) <= s.saleLimit, "Quantity more than available");
        /// Revert if not on allow list
        require(isValidAccessMessage(targetAddress, uniqueNumber, signature), "Invalid signature");

        s._usedVerifiedMessages[uniqueNumber] = true;
        _mint(targetAddress, 1);
    }

    /// Minting for allow list tokens free
    function mintAllowListFree(
        address targetAddress,
        uint16 quantity,
        uint32 uniqueNumber,
        bytes memory signature
    ) external payable {
        /// Revert if allow list sale is not open
        require(s.allowListFreeOpen, "Allow list not open");
        /// Revert if over max allowed per wallet
        require(s._addressData[targetAddress].balance < s._maxPerWallet, "Max per wallet met");
        /// Revert if outside sale limit
        require((s._currentIndex - 1) + quantity <= s.saleLimit, "Quanity more than available");
        /// Revert if not on allow list
        require(isValidAccessMessage(targetAddress, uniqueNumber, signature), "Invalid signature");

        s._usedVerifiedMessages[uniqueNumber] = true;
        _mint(targetAddress, quantity);
    }

    /// Minting for allow list tokens paid
    function mintAllowListPaid(
        address targetAddress,
        uint16 quantity,
        uint32 uniqueNumber,
        bytes memory signature
    ) external payable {
        /// Revert if allow list sale is not open
        require(s.allowListPaidOpen, "Allow list not open");
        /// Revert if over max allowed per wallet
        require(s._addressData[targetAddress].balance < s._maxPerWallet, "Max per wallet met");
        /// Revert if incorrect amount sent
        require(msg.value == s.priceWEI * quantity, "Incorrect value sent");
        /// Revert if outside sale limit
        require((s._currentIndex - 1) + quantity <= s.saleLimit, "Quanity more than available");
        /// Revert if not on allow list
        require(isValidAccessMessage(targetAddress, uniqueNumber, signature), "Invalid signature");

        s._usedVerifiedMessages[uniqueNumber] = true;
        _mint(targetAddress, quantity);
    }

    /// Set signer
    function setSigner(address signer) external onlyEditor {
        s.signer = signer;
    }

    /// Set to enable and disable paid allow list to mint
    function setAllowListPaidOpen(bool newAllowListOpenValue) external onlyEditor {
        s.allowListPaidOpen = newAllowListOpenValue;
    }

    /// Set to enable and disable free allow list to mint
    function setAllowListFreeOpen(bool newAllowListOpenValue) external onlyEditor {
        s.allowListFreeOpen = newAllowListOpenValue;
    }

    /// Get signer
    function getSigner() external view returns (address) {
        return s.signer;
    }

    /// Returns if paid allow list mint is open
    function allowListPaidOpen() external view returns (bool) {
        return s.allowListPaidOpen;
    }

    /// Returns if free allow list mint is open
    function allowListFreeOpen() external view returns (bool) {
        return s.allowListFreeOpen;
    }

    /// Validates mint passes
    function isValidAccessMessage(
        address targetAddress,
        uint32 uniqueNumber,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(uniqueNumber, targetAddress));
        return s.signer == hash.toEthSignedMessageHash().recover(signature);
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