// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {ERC721ATransferRestricted} from
    "poc-ticket/TransferRestriction/ERC721ATransferRestricted.sol";

/**
 * @title Proof of Conference Tickets - Minter module
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
abstract contract Minter is ERC721ATransferRestricted {
    error UnavailableForAirdroppedTokens(uint256);

    /**
     * @dev We use this to reduce the storage requirements for the block number
     * in which the tickets have been minted.
     */
    uint256 private immutable _blockNumberOffset;

    /**
     * @notice The mixHashes at a given block number.
     * @dev Set during purchases.
     */
    mapping(uint256 => uint256) private _mixHashes;

    constructor() {
        // Subtracting 1 guarantees that `block.number - _blockNumberOffset` can
        // never be zero. Hence we can use a zero value to distingish airdropped
        // tokens.
        _blockNumberOffset = block.number - 1;
    }

    /**
     * @notice Callback to mint tokens for a purchase.
     * @dev Store the current `block.number` and `mixHash`, unlike
     * `mintAirdrop`.
     */
    function _mintPurchase(address to, uint256 num) internal {
        uint256 startTokenId = _nextTokenId();
        _mint(to, num);

        // This applies to the entire batch of `num` tokens as per ERC721A
        // default.
        _setExtraDataAt(startTokenId, uint24(block.number - _blockNumberOffset));
        _mixHashes[block.number] = block.difficulty;
    }

    /**
     * @notice Callback to mint tokens during airdrops.
     * @dev Note the difference compared to `_mintPurchase()` as `block.number`
     * and `mixHash` aren't stored.
     */
    function _mintAirdrop(address to, uint256 num) internal virtual {
        _mint(to, num);
    }

    /**
     * @notice ECR721A override to propagate the storage-hitchhiking token info
     * during transfers.
     */
    function _extraData(address, address, uint24 previousExtraData)
        internal
        view
        virtual
        override
        returns (uint24)
    {
        return previousExtraData;
    }

    /**
     * @notice Checks if a given ticket was airdropped.
     * @dev False for purchased tickets.
     */
    function _airdropped(uint256 ticketId)
        internal
        view
        virtual
        returns (bool)
    {
        return _ownershipOf(ticketId).extraData == 0;
    }

    /**
     * @notice Returns the block in which a purchased ticket has been minted.
     * @dev Reverts for airdropped tokens.
     */
    function _mintBlockNumber(uint256 ticketId)
        internal
        view
        virtual
        returns (uint256)
    {
        if (_airdropped(ticketId)) {
            revert UnavailableForAirdroppedTokens(ticketId);
        }

        return uint256(_ownershipOf(ticketId).extraData) + _blockNumberOffset;
    }

    /**
     * @notice Returns the mixHash for a given token.
     * @dev Reverts for airdropped tokens.
     */
    function _mixHashOfTicket(uint256 ticketId)
        internal
        view
        virtual
        returns (uint256)
    {
        return _mixHashes[_mintBlockNumber(ticketId)];
    }
}