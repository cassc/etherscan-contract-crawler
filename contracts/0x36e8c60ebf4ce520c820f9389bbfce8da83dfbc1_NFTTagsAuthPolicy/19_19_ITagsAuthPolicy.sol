// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title TagsAuthPolicy
 * @notice An interface for Guilds to implement that will control authorization for minting tags within that guild
 */
interface ITagsAuthPolicy is IERC165 {
    /**
     * @notice Checks whether a certain address (claimant) may claim a given guild tag that has been revoked or
     * has never been claimed
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param tag The tag being claimed (e.g. 'foo' for foo.my-guild.eth)
     * @param claimant The address attempting to claim the tag (not necessarily the address that will receive it)
     * @param recipient The address that would receive the tag
     * @param extraClaimArgs [Optional] Any guild-specific additional arguments required
     */
    function canClaimTag(
        bytes32 guildEnsNode,
        string calldata tag,
        address claimant,
        address recipient,
        bytes calldata extraClaimArgs
    ) external view returns (bool);

    /**
     * @dev Called by ENSGuilds once a tag has been claimed.
     * Provided for auth policies to update local state, such as erasing an address from an allowlist after that
     * address has successfully minted a tag.
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param tag The tag being claimed (e.g. 'foo' for foo.my-guild.eth)
     * @param claimant The address that claimed the tag (not necessarily the address that received it)
     * @param recipient The address that received receive the tag
     * @param extraClaimArgs [Optional] Any guild-specific additional arguments required
     * @return tagToRevoke Any tag that should be revoked as a consequence of the given tag
     * being claimed. Returns empty string if no tag should be revoked.
     */
    function onTagClaimed(
        bytes32 guildEnsNode,
        string calldata tag,
        address claimant,
        address recipient,
        bytes calldata extraClaimArgs
    ) external returns (string memory tagToRevoke);

    /**
     * @notice Checks whether a given guild tag is eligible to be revoked
     * @param revokedBy The address that would attempt to revoke it
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param tag The tag being revoked (e.g. 'foo' for foo.my-guild.eth)
     * @param extraRevokeArgs Any additional arguments necessary for assessing whether a tag may be revoked
     */
    function canRevokeTag(
        address revokedBy,
        bytes32 guildEnsNode,
        string calldata tag,
        bytes calldata extraRevokeArgs
    ) external view returns (bool);

    /**
     * @notice Called by ENSGuilds once a tag has been revoked.
     * @param revokedBy The address that revoked it
     * @param revokedFrom The address who owned it when it was revoked
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param tag The tag being revoked (e.g. 'foo' for foo.my-guild.eth)
     */
    function onTagRevoked(address revokedBy, address revokedFrom, bytes32 guildEnsNode, string memory tag) external;

    /**
     * @notice Checks whether a tag can be transferred. Implementations may trust that `currentOwner` is the
     * owner of the given tag.
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param tag The tag being revoked (e.g. 'foo' for foo.my-guild.eth)
     * @param transferredBy The address initiating the transfer. May be different than the currentOwner, such
     * as an admin or a marketplace contract
     * @param currentOwner The address currently owning the given tag
     * @param newOwner The address that would receive the tag
     * @param extraTransferArgs Any additional arguments necessary for assessing whether a tag may be transferred
     */
    function canTransferTag(
        bytes32 guildEnsNode,
        string calldata tag,
        address transferredBy,
        address currentOwner,
        address newOwner,
        bytes calldata extraTransferArgs
    ) external view returns (bool);

    /**
     * @notice Called by ENSGuilds once a tag has been transferred
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param tag The tag that was transferred
     * @param transferredBy The address initiating the transfer
     * @param prevOwner The address that previously owned the tag
     * @param newOwner The address that received the tag
     */
    function onTagTransferred(
        bytes32 guildEnsNode,
        string calldata tag,
        address transferredBy,
        address prevOwner,
        address newOwner
    ) external;
}