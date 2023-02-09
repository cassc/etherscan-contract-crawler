// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IRoyaltiesRegistry.sol";
import "./specs/IRarible.sol";
import "../../libraries/BPS.sol";
import "../../tokens/IERC721LA.sol";
import "../../extensions/AccessControl.sol";
import "../../extensions/IAccessControl.sol";
import "./RoyaltiesState.sol";
import "../../extensions/LAInitializable.sol";
import "hardhat/console.sol";

/**
 * @notice Registry to lookup royalty configurations for different royalty specs
 */
contract RoyaltiesRegistry is ERC165, AccessControl, LAInitializable, IRoyaltiesRegistry {
    bytes32 public constant DEPLOYER_ROLE = 0x00;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               CONSTANTS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    uint256 private constant MAX_BPS = 10_000;
    uint256 private constant EDITION_TOKEN_MULTIPLIER = 10e5;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               MODIFIERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    modifier isAuthorized(address collectionAddress, address sender) {
        bool isOwner = hasRole(DEPLOYER_ROLE, msg.sender);
        bool isCollectionAdmin = _hasCollectionAdminRole(
            collectionAddress,
            sender
        );
        bool callerIsCollection = msg.sender == collectionAddress;
        if (!isOwner && !(isCollectionAdmin && callerIsCollection)) {
            revert NotApproved();
        }
        _;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               INITIALIZERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function initialize() public notInitialized  {
        // Deployer Role is needed for manifold 
        _grantRole(DEPLOYER_ROLE, msg.sender);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               IERC165
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IRoyaltiesRegistry)
        returns (bool)
    {
        return
            interfaceId == type(IRoyaltiesRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               AUTHORIZATION
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /// @dev Returns whether `caller` is the admin of the `collectionContract`.
    /// @notice `tx.origin` is used to get the original caller as `msg.sender` is the proxy contract.
    function _hasCollectionAdminRole(address collectionAddress, address sender)
        internal
        view
        returns (bool)
    {
        bool hasRole = IAccessControl(collectionAddress).isAdmin(sender);
        return hasRole;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               PRIMARY ROYALTIES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function registerCollectionRoyaltyReceivers(
        address collectionAddress,
        address sender,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public isAuthorized(collectionAddress, sender) {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();
        _validateRoyaltyReceivers(royaltyReceivers);

        delete state._collectionRoyaltyReceivers[collectionAddress];

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state._collectionRoyaltyReceivers[collectionAddress].push(
                royaltyReceivers[i]
            );
        }
    }

    function registerEditionRoyaltyReceivers(
        address collectionAddress,
        address sender,
        uint256 editionId,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public isAuthorized(collectionAddress, sender) {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();

        _validateRoyaltyReceivers(royaltyReceivers);

        delete state._editionRoyaltyReceivers[collectionAddress][editionId];

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state._editionRoyaltyReceivers[collectionAddress][editionId].push(
                royaltyReceivers[i]
            );
        }
    }

    function registerTokenRoyaltyReceivers(
        address collectionAddress,
        address sender,
        uint256 tokenId,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public isAuthorized(collectionAddress, sender) {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();

        _validateRoyaltyReceivers(royaltyReceivers);

        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        delete state._tokenRoyaltyReceivers[collectionAddress][editionId][
            tokenNumber
        ];

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state
            ._tokenRoyaltyReceivers[collectionAddress][editionId][tokenNumber]
                .push(royaltyReceivers[i]);
        }
    }

    /// @dev Returns the royalties for the given `tokenId`.
    function primaryRoyaltyInfo(
        address collectionAddress,
        uint256 tokenId
    )
        external
        view
        returns (address payable[] memory, uint256[] memory)
    {
        return (
            _getRoyaltyReceivers(collectionAddress, tokenId),
            _getPrimaryRoyaltyBPS(collectionAddress, tokenId)
        );
    }

    /// @dev for external platforms we always return resale royalties
    function _getPrimaryRoyaltyBPS(address collectionAddress, uint256 tokenId)
        internal
        view
        returns (uint256[] memory)
    {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();

        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers = state
            ._tokenRoyaltyReceivers[collectionAddress][editionId][tokenNumber];
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._editionRoyaltyReceivers[
                collectionAddress
            ][editionId];
        }
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._collectionRoyaltyReceivers[
                collectionAddress
            ];
        }
        uint256[] memory royaltyBPS = new uint256[](royaltyReceivers.length);

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            royaltyBPS[i] = royaltyReceivers[i].primarySalePercentage;
        }

        return royaltyBPS;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               SECONDARY ROYALTIES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /// @dev for external platforms we always return resale royalties
    function _getRoyaltyReceivers(address collectionAddress, uint256 tokenId)
        internal
        view
        returns (address payable[] memory)
    {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();
        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers = state
            ._tokenRoyaltyReceivers[collectionAddress][editionId][tokenNumber];
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._editionRoyaltyReceivers[
                collectionAddress
            ][editionId];
        }
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._collectionRoyaltyReceivers[
                collectionAddress
            ];
        }

        address payable[] memory receivers = new address payable[](
            royaltyReceivers.length
        );

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            receivers[i] = royaltyReceivers[i].wallet;
        }

        return receivers;
    }

    /// @dev for external platforms we always return resale royalties
    function _getSecondaryRoyaltyBPS(address collectionAddress, uint256 tokenId)
        internal
        view
        returns (uint256[] memory)
    {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();

        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers = state
            ._tokenRoyaltyReceivers[collectionAddress][editionId][tokenNumber];
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._editionRoyaltyReceivers[
                collectionAddress
            ][editionId];
        }
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._collectionRoyaltyReceivers[
                collectionAddress
            ];
        }
        uint256[] memory royaltyBPS = new uint256[](royaltyReceivers.length);

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            royaltyBPS[i] = royaltyReceivers[i].secondarySalePercentage;
        }

        return royaltyBPS;
    }

    /// @dev see: EIP-2981
    function royaltyInfo(
        address collectionAddress,
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();

        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers = state
            ._tokenRoyaltyReceivers[collectionAddress][editionId][tokenNumber];

        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._editionRoyaltyReceivers[
                collectionAddress
            ][editionId];
        }

        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._collectionRoyaltyReceivers[
                collectionAddress
            ];
        }

        if (royaltyReceivers.length > 1) {
            revert MultipleRoyaltyRecievers();
        }

        if (royaltyReceivers.length == 0) {
            return (address(this), 0);
        }

        return (
            royaltyReceivers[0].wallet,
            BPS._calculatePercentage(
                salePrice,
                royaltyReceivers[0].secondarySalePercentage
            )
        );
    }

    /// @dev CreatorCore - Supports Manifold, ArtBlocks
    function getRoyalties(address collectionAddress, uint256 tokenId)
        public
        view
        returns (address payable[] memory, uint256[] memory)
    {
        return (
            _getRoyaltyReceivers(collectionAddress, tokenId),
            _getSecondaryRoyaltyBPS(collectionAddress, tokenId)
        );
    }

    /// @dev Foundation
    function getFees(address collectionAddress, uint256 editionId)
        public
        view
        returns (address payable[] memory, uint256[] memory)
    {
        return getRoyalties(collectionAddress, editionId);
    }

    /// @dev Rarible: RoyaltiesV1
    function getFeeBps(address collectionAddress, uint256 tokenId)
        public
        view
        returns (uint256[] memory)
    {
        return _getSecondaryRoyaltyBPS(collectionAddress, tokenId);
    }

    /// @dev Rarible: RoyaltiesV1
    function getFeeRecipients(address collectionAddress, uint256 editionId)
        public
        view
        returns (address payable[] memory)
    {
        return _getRoyaltyReceivers(collectionAddress, editionId);
    }

    /// @dev Rarible: RoyaltiesV2
    function getRaribleV2Royalties(address collectionAddress, uint256 tokenId)
        public
        view
        returns (IRaribleV2.Part[] memory)
    {
        address payable[] memory royaltyReceivers = _getRoyaltyReceivers(
            collectionAddress,
            tokenId
        );

        if (royaltyReceivers.length == 0) {
            return new IRaribleV2.Part[](0);
        }

        uint256[] memory bps = _getSecondaryRoyaltyBPS(
            collectionAddress,
            tokenId
        );

        IRaribleV2.Part[] memory parts = new IRaribleV2.Part[](
            royaltyReceivers.length
        );

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            parts[i] = IRaribleV2.Part({
                account: payable(royaltyReceivers[i]),
                value: uint96(bps[i])
            });
        }
        return parts;
    }

    /// @dev CreatorCore - Support for KODA
    function getKODAV2RoyaltyInfo(address collectionAddress, uint256 tokenId)
        public
        view
        returns (address payable[] memory recipients_, uint256[] memory bps)
    {
        return (
            _getRoyaltyReceivers(collectionAddress, tokenId),
            _getSecondaryRoyaltyBPS(collectionAddress, tokenId)
        );
    }

    /// @dev CreatorCore - Support for Zora
    function convertBidShares(address collectionAddress, uint256 tokenId)
        public
        view
        returns (address payable[] memory recipients_, uint256[] memory bps)
    {
        return (
            _getRoyaltyReceivers(collectionAddress, tokenId),
            _getSecondaryRoyaltyBPS(collectionAddress, tokenId)
        );
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                         INTERNAL / PUBLIC HELPERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function parseEditionFromTokenId(address collectionAddress, uint256 tokenId)
        internal
        view
        returns (uint256 editionId, uint256 tokenNumber)
    {
        (, bytes memory result) = collectionAddress.staticcall(
            abi.encodeWithSignature("parseEditionFromTokenId(uint256)", tokenId)
        );

        (editionId, tokenNumber) = abi.decode(result, (uint256, uint256));
    }

    function _validateRoyaltyReceivers(
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) internal pure {
        (
            uint256 totalPrimarySaleBPS,
            uint256 totalSecondarySaleBPS
        ) = _calculateTotalRoyalties(royaltyReceivers);

        if (totalPrimarySaleBPS > MAX_BPS) {
            revert PrimarySalePercentageOutOfRange();
        }

        if (totalSecondarySaleBPS > MAX_BPS) {
            revert SecondarySalePercentageOutOfRange();
        }

        if (totalPrimarySaleBPS != MAX_BPS) {
            revert PrimarySalePercentageNotEqualToMax();
        }
    }

    function _calculateTotalRoyalties(
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    )
        internal
        pure
        returns (uint256 totalFirstSaleBPS, uint256 totalSecondarySaleBPS)
    {
        uint256 _totalFirstSaleBPS;
        uint256 _totalSecondarySaleBPS;
        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            _totalFirstSaleBPS += royaltyReceivers[i].primarySalePercentage;
            _totalSecondarySaleBPS += royaltyReceivers[i]
                .secondarySalePercentage;
        }

        return (_totalFirstSaleBPS, _totalSecondarySaleBPS);
    }
}