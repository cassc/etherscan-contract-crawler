// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ReverseClaimer } from "@ensdomains/ens-contracts/contracts/reverseRegistrar/ReverseClaimer.sol";
import { ENS } from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";

import { BaseTagsAuthPolicy } from "./BaseTagsAuthPolicy.sol";
import { IENSGuilds } from "../ensGuilds/interfaces/IENSGuilds.sol";
import { ITagsAuthPolicy } from "./ITagsAuthPolicy.sol"; // solhint-disable-line no-unused-import

/**
 * @title AllowlistTagsAuthPolicy
 * @notice A common implementation of TagsAuthPolicy that can be used to restrict minting
 * guild tags to only allowlisted addresses.
 * A separate allowlist is maintained per each guild, and may only be updated by that guild's registered admin.
 */
contract AllowlistTagsAuthPolicy is BaseTagsAuthPolicy, ReverseClaimer {
    mapping(bytes32 => mapping(address => bool)) public guildAllowlists;

    // solhint-disable-next-line no-empty-blocks
    constructor(
        ENS _ensRegistry,
        IENSGuilds ensGuilds,
        address reverseRecordOwner
    ) BaseTagsAuthPolicy(ensGuilds) ReverseClaimer(_ensRegistry, reverseRecordOwner) {}

    function allowMint(bytes32 guildHash, address minter) external onlyGuildAdmin(guildHash) {
        guildAllowlists[guildHash][minter] = true;
    }

    function disallowMint(bytes32 guildHash, address minter) external onlyGuildAdmin(guildHash) {
        guildAllowlists[guildHash][minter] = false;
    }

    /**
     * @inheritdoc ITagsAuthPolicy
     */
    function canClaimTag(
        bytes32 guildHash,
        string calldata,
        address claimant,
        address,
        bytes calldata
    ) external view virtual override returns (bool) {
        return guildAllowlists[guildHash][claimant];
    }

    /**
     * @dev removes the claimant from the guild's allowlist
     */
    function _onTagClaimed(
        bytes32 guildHash,
        string calldata,
        address claimant,
        address,
        bytes calldata
    ) internal virtual override returns (string memory tagToRevoke) {
        guildAllowlists[guildHash][claimant] = false;
        return "";
    }

    /**
     * @inheritdoc ITagsAuthPolicy
     */
    function canRevokeTag(
        address,
        bytes32,
        string calldata,
        bytes calldata
    ) external view virtual override returns (bool) {
        return false;
    }

    /**
     * @inheritdoc ITagsAuthPolicy
     */
    function canTransferTag(
        bytes32,
        string calldata,
        address transferredBy,
        address currentOwner,
        address,
        bytes calldata
    ) external pure returns (bool) {
        return transferredBy == currentOwner;
    }

    function _onTagRevoked(address, address, bytes32, string memory) internal virtual override {
        return;
    }

    function _onTagTransferred(bytes32, string calldata, address, address, address) internal virtual override {
        return;
    }
}