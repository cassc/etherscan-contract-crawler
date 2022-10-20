// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDiamond} from "./LibDiamond.sol";
import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";
import {IERC721A} from "../interfaces/IERC721A.sol";
import {PriceConsumer} from "./PriceConsumer.sol";

library ERC721ALib {
    error TokenIsSoulbound();

    uint256 constant START_TOKEN_ID = 0;
    // Mask of an entry in packed address data.
    uint256 constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `extraData` in packed ownership.
    uint256 constant _BITPOS_EXTRA_DATA = 232;

    // The mask of the lower 160 bits for addresses.
    uint256 constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 constant _BITPOS_START_TIMESTAMP = 160;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 constant _BITPOS_NEXT_INITIALIZED = 225;

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 startTokenId = s.currentIndex;
        if (quantity == 0) revert IERC721A.MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            s.packedAddressData[to] +=
                quantity *
                ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            s.packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) |
                    _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert IERC721A.MintToZeroAddress();

            s.currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags)
        internal
        view
        returns (uint256 result)
    {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(
                owner,
                or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags)
            )
        }
    }

    // /**
    //  * @dev Hook that is called before a set of serially-ordered token IDs
    //  * are about to be transferred. This includes minting.
    //  * And also called before burning one token.
    //  *
    //  * `startTokenId` - the first token ID to be transferred.
    //  * `quantity` - the amount to be transferred.
    //  *
    //  * Calling conditions:
    //  *
    //  * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
    //  * transferred to `to`.
    //  * - When `from` is zero, `tokenId` will be minted for `to`.
    //  * - When `to` is zero, `tokenId` will be burned by `from`.
    //  * - `from` and `to` are never both zero.
    //  */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Nested if save gas
        if (s.isSoulbound)
            if ((from != address(0) && to != address(0)))
                revert TokenIsSoulbound();
    }

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
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
        uint256 startTokenId,
        uint256 quantity
    ) internal {}

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity)
        internal
        pure
        returns (uint256 result)
    {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) internal returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal returns (uint24) {}

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return
            (s.packedAddressData[owner] >> ERC721ALib._BITPOS_NUMBER_MINTED) &
            _BITMASK_ADDRESS_DATA_ENTRY;
    }

    // Convert USD to Wei
    function convertUSDtoWei(uint256 _price) internal view returns (uint256) {
        /** 1e18 is equivalent to one eth in wei. 1e6 needed to convert price return to correct decimals (8).  */
        return (1e18 / (PriceConsumer.getLatestPrice() / 1e6)) * _price;
    }
}