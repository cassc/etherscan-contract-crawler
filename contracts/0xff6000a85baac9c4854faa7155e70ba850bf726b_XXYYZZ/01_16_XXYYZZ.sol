// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {XXYYZZMetadata} from "./XXYYZZMetadata.sol";
import {XXYYZZBurn} from "./XXYYZZBurn.sol";
import {XXYYZZSeaDrop} from "./XXYYZZSeaDrop.sol";
import {XXYYZZCore} from "./XXYYZZCore.sol";
import {XXYYZZRerollFinalize} from "./XXYYZZRerollFinalize.sol";
import {XXYYZZCore} from "./XXYYZZCore.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Base64} from "solady/utils/Base64.sol";

/**
 * @title XXYYZZ
 * @author emo.eth
 * @notice XXYYZZ is a collection of fully onchain, collectible colors. Each token has a unique hex value.
 *         Tokens may be "rerolled" to new hex values, unless they are "finalized," in which case, they are immutable.
 *
 *         Finalizing tokens also adds the finalizer's wallet address to the token's metadata.
 *         Tokens may be burned, which removes it from the token supply, but unless the token was finalized, its
 *         particular hex value may be minted or rerolled again.
 *
 *         Mints and rerolls are pseudorandom by default, unless one of the "Specific" methods is called.
 *         To prevent front-running "specific" mint transactions, the XXYYZZ contract uses a commit-reveal scheme.
 *         Users must commit a hash of their desired hex value with a secret salt, wait at least one minute, and then
 *         submit their mint or reroll transaction with the original hex value(s) and salt.
 *         Multiple IDs may be minted or rerolled in a single transaction by committixng the result of hash of all IDs in order
 *         with a single secret salt.
 *         In batch methods, unavailable IDs are skipped, and excess payment is refunded to the caller.
 */
contract XXYYZZ is XXYYZZMetadata, XXYYZZBurn, XXYYZZSeaDrop, XXYYZZRerollFinalize {
    using LibString for uint256;
    using LibString for address;
    using Base64 for bytes;

    constructor(
        address initialOwner,
        address creatorPayout,
        uint256 maxBatchSize,
        uint24[] memory preMintIds,
        address seaDrop
    ) XXYYZZSeaDrop(seaDrop, creatorPayout, initialOwner, maxBatchSize) {
        for (uint256 i; i < preMintIds.length;) {
            _mint(initialOwner, preMintIds[i]);
            _finalizeToken(preMintIds[i], initialOwner);
            unchecked {
                ++i;
            }
        }
        _numMinted = uint32(preMintIds.length);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(XXYYZZSeaDrop, XXYYZZCore)
        returns (bool)
    {
        return XXYYZZSeaDrop.supportsInterface(interfaceId);
    }
}