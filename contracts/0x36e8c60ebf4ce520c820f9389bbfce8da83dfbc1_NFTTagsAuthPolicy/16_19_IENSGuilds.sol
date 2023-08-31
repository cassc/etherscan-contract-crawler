// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC1155MetadataURI } from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

interface IENSGuilds is IERC1155MetadataURI {
    /** Events */
    event Registered(bytes32 indexed guildEnsNode);
    event Deregistered(bytes32 indexed guildEnsNode);
    event TagClaimed(bytes32 indexed guildEnsNode, bytes32 indexed tagHash, address recipient);
    event TagTransferred(bytes32 indexed guildEnsNode, bytes32 indexed tagHash, address from, address to);
    event TagRevoked(bytes32 indexed guildEnsNode, bytes32 indexed tagHash);
    event FeePolicyUpdated(bytes32 indexed guildEnsNode, address feePolicy);
    event TagsAuthPolicyUpdated(bytes32 indexed guildEnsNode, address tagsAuthPolicy);
    event AdminTransferred(bytes32 indexed guildEnsNode, address newAdmin);
    event SetActive(bytes32 indexed guildEnsNode, bool active);
    event TokenUriSet(bytes32 indexed guildEnsNode, string uri);

    /* Functions */

    /**
     * @notice Registers a new guild from an existing ENS domain.
     * Caller must be the ENS node's owner and ENSGuilds must have been designated an "operator" for the caller.
     * @param ensName The guild's full ENS name (e.g. 'my-guild.eth')
     * @param guildAdmin The address that will administrate this guild
     * @param feePolicy The address of an implementation of FeePolicy to use for minting new tags within this guild
     * @param tagsAuthPolicy The address of an implementation of TagsAuthPolicy to use for minting new tags
     * within this guild
     */
    function registerGuild(
        string calldata ensName,
        address guildAdmin,
        address feePolicy,
        address tagsAuthPolicy
    ) external;

    /**
     * @notice De-registers a registered guild.
     * Designates guild as inactive and marks all tags previously minted for that guild as eligible for revocation.
     * @param guildEnsNode The ENS namehash of the guild's domain
     */
    function deregisterGuild(bytes32 guildEnsNode) external;

    /**
     * @notice Claims a guild tag
     * @param guildEnsNode The namehash of the guild for which the tag should be claimed (e.g. namehash('my-guild.eth'))
     * @param tag The tag name to claim (e.g. 'foo' for foo.my-guild.eth). Assumes `tag` is already normalized per
     * ENS Name Processing rules
     * @param recipient The address that will receive this guild tag (usually same as the caller)
     * @param extraClaimArgs [Optional] Any additional arguments necessary for guild-specific logic,
     *  such as authorization
     */
    function claimGuildTag(
        bytes32 guildEnsNode,
        string calldata tag,
        address recipient,
        bytes calldata extraClaimArgs
    ) external payable;

    /**
     * @notice Transfers an existing guild tag
     * @param guildEnsNode The namehash of the guild for which the tag should be transferred
     * (e.g. namehash('my-guild.eth'))
     * @param tag The tag name to transfer (e.g. 'foo' for foo.my-guild.eth). Assumes `tag` is already normalized per
     * ENS Name Processing rules
     * @param recipient The address that will receive this guild tag
     * @param extraTransferArgs [Optional] Any additional arguments necessary for guild-specific logic,
     *  such as authorization
     */
    function transferGuildTag(
        bytes32 guildEnsNode,
        string calldata tag,
        address recipient,
        bytes calldata extraTransferArgs
    ) external;

    /**
     * @notice Claims multiple tags for a guild at once
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param tags Tags to be claimed
     * @param recipients Recipients of each tag to be claimed
     * @param extraClaimArgs Per-tag extra arguments required for guild-specific logic, such as authorization.
     * Must have same length as array of tagHashes, even if each array element is itself empty bytes
     */
    function claimGuildTagsBatch(
        bytes32 guildEnsNode,
        string[] calldata tags,
        address[] calldata recipients,
        bytes[] calldata extraClaimArgs
    ) external payable;

    /**
     * @notice Returns the current owner of the given guild tag.
     * Returns address(0) if no such guild or tag exists, or if the guild has been deregistered.
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param tagHash The ENS namehash of the tag (e.g. keccak256('foo') for foo.my-guild.eth)
     */
    function tagOwner(bytes32 guildEnsNode, bytes32 tagHash) external view returns (address);

    /**
     * @notice Attempts to revoke an existing guild tag, if authorized by the guild's AuthPolicy.
     * Deregistered guilds will bypass auth checks for revocation of all tags.
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param tag The tag to revoke
     * @param extraData [Optional] Any additional arguments necessary for assessing whether a tag may be revoked
     */
    function revokeGuildTag(bytes32 guildEnsNode, string calldata tag, bytes calldata extraData) external;

    /**
     * @notice Attempts to revoke multiple guild tags
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param tags tags to revoke
     * @param extraData Additional arguments necessary for assessing whether a tag may be revoked
     */
    function revokeGuildTagsBatch(bytes32 guildEnsNode, string[] calldata tags, bytes[] calldata extraData) external;

    /**
     * @notice Updates the FeePolicy for an existing guild. May only be called by the guild's registered admin.
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param feePolicy The address of an implementation of FeePolicy to use for minting new tags within this guild
     */
    function updateGuildFeePolicy(bytes32 guildEnsNode, address feePolicy) external;

    /**
     * @notice Updates the TagsAuthPolicy for an existing guild. May only be called by the guild's registered admin.
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param tagsAuthPolicy The address of an implementation of TagsAuthPolicy to use for
     * minting new tags within this guild
     */
    function updateGuildTagsAuthPolicy(bytes32 guildEnsNode, address tagsAuthPolicy) external;

    /**
     * @notice Sets the metadata URI string for fetching metadata for a guild's tag NFTs.
     * May only be called by the guild's registered admin.
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param uri The ERC1155 metadata URL template
     */
    function setGuildTokenUri(bytes32 guildEnsNode, string calldata uri) external;

    /**
     * @notice Sets a guild as active or inactive. May only be called by the guild's registered admin.
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param active The new status
     */
    function setGuildActive(bytes32 guildEnsNode, bool active) external;

    /**
     * @notice Returns the current admin registered for the given guild.
     * @param guildEnsNode The ENS namehash of the guild's domain
     */
    function guildAdmin(bytes32 guildEnsNode) external view returns (address);

    /**
     * @notice Transfers the role of guild admin to the given address.
     * May only be called by the guild's registered admin.
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param newAdmin The new admin
     */
    function transferGuildAdmin(bytes32 guildEnsNode, address newAdmin) external;

    /**
     * @notice Registers a resolver for the guild's root ENS name that will
     * answer queries about the parent name itself, or any child names that are
     * not Guild tags
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param fallbackResolver The fallback resolver
     */
    function setFallbackResolver(bytes32 guildEnsNode, address fallbackResolver) external;
}