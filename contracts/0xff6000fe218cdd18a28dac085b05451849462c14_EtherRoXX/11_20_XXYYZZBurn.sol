// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {XXYYZZCore} from "./XXYYZZCore.sol";

abstract contract XXYYZZBurn is XXYYZZCore {
    //////////
    // BURN //
    //////////

    /**
     * @notice Permanently burn a token that the caller owns or is approved for.
     * @param xxyyzz The token to burn.
     * @param onlyFinalized If true, only tokens that have been finalized can be burned. Useful if an approved operator
     *                      is burning tokens on behalf of a user.
     */
    function burn(uint256 xxyyzz, bool onlyFinalized) public {
        // cannot overflow as there are at most 2^24 tokens, and _numBurned is a uint32
        unchecked {
            _numBurned += 1;
        }
        if (onlyFinalized) {
            if (!_isFinalized(xxyyzz)) {
                revert OnlyFinalized();
            }
        }
        _burn(msg.sender, xxyyzz);
    }

    /**
     * @notice Permanently burn multiple tokens. All must be owned by the same address.
     * @param ids The tokens to burn.
     * @param onlyFinalized If true, only tokens that have been finalized can be burned. Useful if an approved operator
     *                      is burning tokens on behalf of a user.
     */
    function batchBurn(uint256[] calldata ids, bool onlyFinalized) public {
        if (ids.length == 0) {
            revert NoIdsProvided();
        }
        uint256 packedOwnerFinalizedSlot = _packedOwnershipSlot(ids[0]);
        address initialTokenOwner = address(uint160(packedOwnerFinalizedSlot));
        if (onlyFinalized) {
            if (packedOwnerFinalizedSlot < type(uint160).max) {
                revert OnlyFinalized();
            }
        }
        // validate that msg.sender has approval to burn all tokens
        if (initialTokenOwner != msg.sender) {
            if (!isApprovedForAll(initialTokenOwner, msg.sender)) {
                revert BatchBurnerNotApprovedForAll();
            }
        }
        // safe because there are at most 2^24 tokens, and ownerships are checked
        unchecked {
            _numBurned += uint32(ids.length);
        }
        _burn(ids[0]);
        for (uint256 i = 1; i < ids.length;) {
            uint256 id = ids[i];
            packedOwnerFinalizedSlot = _packedOwnershipSlot(id);
            address owner = address(uint160(packedOwnerFinalizedSlot));
            // ensure that all tokens are owned by the same address
            if (owner != initialTokenOwner) {
                revert OwnerMismatch();
            }
            if (onlyFinalized) {
                if (packedOwnerFinalizedSlot < type(uint160).max) {
                    revert OnlyFinalized();
                }
            }
            // no need to specify msg.sender since caller is approved for all tokens
            // this also checks token exists
            _burn(id);
            unchecked {
                ++i;
            }
        }
    }
}