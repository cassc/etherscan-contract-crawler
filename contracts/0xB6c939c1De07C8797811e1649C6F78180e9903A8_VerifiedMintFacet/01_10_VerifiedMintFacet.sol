// SPDX-License-Identifier: MIT
/// Adapted from this article https://dev.to/lilcoderman/create-a-whitelist-for-your-nft-project-1g55
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {AppStorage, Modifiers} from "../libraries/LibAppStorage.sol";
import "../libraries/LibERC721.sol";

import "hardhat/console.sol";

contract VerifiedMintFacet is Modifiers {
    using ECDSA for bytes32;

    /// Mints number of tokens provided during general sale
    function mintOneFree(
        address targetAddress,
        uint32 uniqueNumber,
        bytes memory signature
    ) external payable {
        /// Revert if message already used
        require(!s._usedVerifiedMessages[uniqueNumber], "Verified message is used");
        /// Revert if outside sale limit
        require((s._currentIndex - 1) <= s.saleLimit, "Quantity more than available");

        require(isValidAccessMessage(targetAddress, uniqueNumber, signature), "Invalid signature");
        s._usedVerifiedMessages[uniqueNumber] = true;
        _mint(targetAddress, 1);
    }

    /// Set signer
    function setSigner(address signer) external onlyEditor {
        s.signer = signer;
    }

    /// Get signer
    function getSigner() external view returns (address) {
        return s.signer;
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