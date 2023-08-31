// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { ITagsAuthPolicy } from "./ITagsAuthPolicy.sol";
import { IENSGuilds } from "../ensGuilds/interfaces/IENSGuilds.sol";

/**
 * @title BaseTagsAuthPolicy
 * @notice An base implementation of ITagsAuthPolicy
 */
abstract contract BaseTagsAuthPolicy is ITagsAuthPolicy, ERC165, Context, ReentrancyGuard {
    using ERC165Checker for address;

    IENSGuilds public immutable ensGuilds;

    constructor(IENSGuilds _ensGuilds) {
        // solhint-disable-next-line reason-string, custom-errors
        require(_ensGuilds.supportsInterface(type(IENSGuilds).interfaceId));
        ensGuilds = _ensGuilds;
    }

    modifier onlyEnsGuildsContract() {
        // solhint-disable-next-line reason-string, custom-errors
        require(_msgSender() == address(ensGuilds));
        _;
    }

    modifier onlyGuildAdmin(bytes32 guildEnsNode) {
        // solhint-disable-next-line reason-string, custom-errors
        require(ensGuilds.guildAdmin(guildEnsNode) == _msgSender());
        _;
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceID == type(ITagsAuthPolicy).interfaceId || super.supportsInterface(interfaceID);
    }

    /**
     * @inheritdoc ITagsAuthPolicy
     * @dev protects against reentrancy and checks that caller is the Guilds contract. Updating any state
     * is deferred to the implementation.
     */
    function onTagClaimed(
        bytes32 guildEnsNode,
        string calldata tag,
        address claimant,
        address recipient,
        bytes calldata extraClaimArgs
    ) external override nonReentrant onlyEnsGuildsContract returns (string memory tagToRevoke) {
        return _onTagClaimed(guildEnsNode, tag, claimant, recipient, extraClaimArgs);
    }

    /**
     * @dev entrypoint for implementations of BaseTagsAuthPolicy that need to update any state
     */
    function _onTagClaimed(
        bytes32 guildEnsNode,
        string calldata tag,
        address claimant,
        address recipient,
        bytes calldata extraClaimArgs
    ) internal virtual returns (string memory tagToRevoke);

    /**
     * @inheritdoc ITagsAuthPolicy
     * @dev protects against reentrancy and checks that caller is the Guilds contract. Updating any state
     * is deferred to the implementation.
     */
    function onTagRevoked(
        address revokedBy,
        address revokedFrom,
        bytes32 guildEnsNode,
        string memory tag
    ) external override nonReentrant onlyEnsGuildsContract {
        _onTagRevoked(revokedBy, revokedFrom, guildEnsNode, tag);
    }

    /**
     * @dev entrypoint for implementations of BaseTagsAuthPolicy that need to update any state
     */
    function _onTagRevoked(
        address revokedBy,
        address revokedFrom,
        bytes32 guildEnsNode,
        string memory tag
    ) internal virtual;

    /**
     * @inheritdoc ITagsAuthPolicy
     * @dev protects against reentrancy and checks that caller is the Guilds contract. Updating any state
     * is deferred to the implementation.
     */
    function onTagTransferred(
        bytes32 guildEnsNode,
        string calldata tag,
        address transferredBy,
        address prevOwner,
        address newOwner
    ) external override nonReentrant onlyEnsGuildsContract {
        _onTagTransferred(guildEnsNode, tag, transferredBy, prevOwner, newOwner);
    }

    /**
     * @dev entrypoint for implementations of BaseTagsAuthPolicy that need to update any state
     */
    function _onTagTransferred(
        bytes32 guildEnsNode,
        string calldata tag,
        address transferredBy,
        address prevOwner,
        address newOwner
    ) internal virtual;
}