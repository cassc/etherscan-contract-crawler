// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ReverseClaimer } from "@ensdomains/ens-contracts/contracts/reverseRegistrar/ReverseClaimer.sol";
import { ENS } from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import { StringParsing } from "../libraries/StringParsing.sol";
import { BaseTagsAuthPolicy } from "./BaseTagsAuthPolicy.sol";
import { IENSGuilds } from "../ensGuilds/interfaces/IENSGuilds.sol";
import { ITagsAuthPolicy } from "./ITagsAuthPolicy.sol"; // solhint-disable-line no-unused-import

/**
 * @title NFTTagsAuthPolicy
 * @notice A common implementation of TagsAuthPolicy that can be used to restrict minting guild tags to only addresses
 * that own an NFT from a given collection, configured per-guild by each guild's admin. An address may mint a tag once
 * per each item in the collection that it owns. Minting two tags from the same TokenID will result in the first being
 * revoked once the second is minted, regardless of whether ownership of that TokenID has changed.
 *
 * A user's guild tag is eligible for revocation once that user ceases to own the TokenID used in minting that tag.
 */
contract NFTTagsAuthPolicy is BaseTagsAuthPolicy, ReverseClaimer {
    using ERC165Checker for address;
    using StringParsing for bytes;
    using Strings for string;

    error TokenIDTagMustMatchCallerTokenID();

    enum TokenStandard {
        ERC721,
        ERC1155
    }
    struct TagClaim {
        string tag;
        address claimedBy;
    }
    struct GuildInfo {
        address tokenContract;
        TokenStandard tokenStandard;
        mapping(uint256 => TagClaim) tagClaims;
    }
    mapping(bytes32 => GuildInfo) public guilds;

    // solhint-disable-next-line no-empty-blocks
    constructor(
        ENS _ensRegistry,
        IENSGuilds ensGuilds,
        address reverseRecordOwner
    ) BaseTagsAuthPolicy(ensGuilds) ReverseClaimer(_ensRegistry, reverseRecordOwner) {}

    /**
     * @notice Registers the specific NFT collection that a user must be a member of to mint a guild tag
     * @param guildEnsNode The ENS namehash of the guild's domain
     * @param tokenContract The ERC721 or ERC1155 collection to use
     */
    function setTokenContract(bytes32 guildEnsNode, address tokenContract) external onlyGuildAdmin(guildEnsNode) {
        // token contract must be ERC721 or ERC1155
        if (tokenContract.supportsInterface(type(IERC721).interfaceId)) {
            guilds[guildEnsNode].tokenStandard = TokenStandard.ERC721;
        } else if (tokenContract.supportsInterface(type(IERC1155).interfaceId)) {
            guilds[guildEnsNode].tokenStandard = TokenStandard.ERC1155;
        } else {
            // solhint-disable-next-line reason-string, custom-errors
            revert();
        }

        guilds[guildEnsNode].tokenContract = tokenContract;
    }

    /**
     * @inheritdoc ITagsAuthPolicy
     * @dev Expects that the caller will supply the NFT's TokenID in `extraClaimArgs`.
     * The caller must own the given TokenID.
     */
    function canClaimTag(
        bytes32 guildEnsNode,
        string calldata tag,
        address claimant,
        address,
        bytes calldata extraClaimArgs
    ) external view virtual override returns (bool) {
        GuildInfo storage guildInfo = guilds[guildEnsNode];
        address tokenContract = guildInfo.tokenContract;

        // parse NFT token ID from the tag claim args
        if (extraClaimArgs.length != 32) {
            return false;
        }
        uint256 nftTokenId = uint256(bytes32(extraClaimArgs));

        // check that claimant owns this NFT
        bool ownsNFT = false;
        if (guildInfo.tokenStandard == TokenStandard.ERC721) {
            ownsNFT = IERC721(tokenContract).ownerOf(nftTokenId) == claimant;
        } else {
            ownsNFT = IERC1155(tokenContract).balanceOf(claimant, nftTokenId) > 0;
        }
        if (!ownsNFT) {
            return false;
        }

        // if the tag looks like a token ID, it should be the same as the token ID
        // used to authorize the mint
        (bool isUint, uint256 parsedTokenID) = bytes(tag).parseUint256();
        if (isUint && parsedTokenID != nftTokenId) {
            revert TokenIDTagMustMatchCallerTokenID();
        }

        return true;
    }

    /**
     * @dev records the latest tag minted from the given TokenID (via extraClaimArgs), and returns whichever
     * tag was last minted from the same TokenID.
     */
    function _onTagClaimed(
        bytes32 guildEnsNode,
        string calldata tag,
        address claimant,
        address,
        bytes calldata extraClaimArgs
    ) internal virtual override returns (string memory tagToRevoke) {
        uint256 nftTokenId = uint256(bytes32(extraClaimArgs));

        tagToRevoke = guilds[guildEnsNode].tagClaims[nftTokenId].tag;

        guilds[guildEnsNode].tagClaims[nftTokenId].tag = tag;
        guilds[guildEnsNode].tagClaims[nftTokenId].claimedBy = claimant;

        return tagToRevoke;
    }

    /**
     * @inheritdoc ITagsAuthPolicy
     */
    function canRevokeTag(
        address,
        bytes32 guildEnsNode,
        string calldata tag,
        bytes calldata extraRevokeArgs
    ) external view virtual override returns (bool) {
        if (extraRevokeArgs.length != 32) {
            return false;
        }
        uint256 nftTokenId = uint256(bytes32(extraRevokeArgs));

        GuildInfo storage guildInfo = guilds[guildEnsNode];
        address tokenContract = guildInfo.tokenContract;

        // check that the given tag was indeed claimed from the given NFT
        if (!guildInfo.tagClaims[nftTokenId].tag.equal(tag)) {
            return false;
        }

        // check that the current owner of the given NFT is the same as the owner when the tag was claimed
        address previousClaimant = guildInfo.tagClaims[nftTokenId].claimedBy;
        if (guildInfo.tokenStandard == TokenStandard.ERC721) {
            address currentTokenOwner = IERC721(tokenContract).ownerOf(nftTokenId);
            return currentTokenOwner != previousClaimant;
        } else {
            return IERC1155(tokenContract).balanceOf(previousClaimant, nftTokenId) == 0;
        }
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