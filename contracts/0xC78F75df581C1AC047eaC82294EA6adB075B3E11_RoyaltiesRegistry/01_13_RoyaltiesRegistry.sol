// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";

import "./IRoyaltiesRegistry.sol";
import "./specs/IRarible.sol";
import "../../libraries/BPS.sol";

/**
 * @notice Registry to lookup royalty configurations for different royalty specs
 */
contract RoyaltiesRegistry is ERC165, OwnableUpgradeable, IRoyaltiesRegistry {
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               LIBRARIES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    using AddressUpgradeable for address;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               CONSTANTS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    uint256 private constant MAX_BPS = 10000;
    uint256 private constant EDITION_TOKEN_MULTIPLIER = 10e5;
    bytes32 public constant DEPLOYER_ROLE = 0x00;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               STORAGE
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    struct RoyaltyReceiver {
        address payable wallet;
        uint32 primarySalePercentage;
        uint64 secondarySalePercentage;
    }

    struct RoyaltiesRegistryState {
        mapping(address => RoyaltyReceiver[]) _collectionPrimaryRoyaltyReceivers;
        mapping(address => RoyaltyReceiver[]) _collectionSecondaryRoyaltyReceivers;
        mapping(address => mapping(uint256 => RoyaltyReceiver[])) _editionPrimaryRoyaltyReceivers;
        mapping(address => mapping(uint256 => RoyaltyReceiver[])) _editionSecondaryRoyaltyReceivers;
        mapping(address => mapping(uint256 => mapping(uint256 => RoyaltyReceiver[]))) _tokenPrimaryRoyaltyReceivers;
        mapping(address => mapping(uint256 => mapping(uint256 => RoyaltyReceiver[]))) _tokenSecondaryRoyaltyReceivers;
    }

    function _getRoyaltiesRegistryState()
        internal
        pure
        returns (RoyaltiesRegistryState storage state)
    {
        bytes32 position = keccak256("liveart.RoyaltiesRegistry");
        assembly {
            state.slot := position
        }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               MODIFIERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    modifier isAuthorized(address collectionAddress) {
        if (!_isCollectionDeploy(collectionAddress)) {
            revert NotApproved();
        }
        _;
    }

    modifier isOwner() {
        if (owner() != msg.sender) {
            revert NotApproved();
        }
        _;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               INITIALIZERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function initialize() public initializer {
        __Ownable_init_unchained();
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
    function _isCollectionDeploy(address collectionAddress)
        internal
        view
        returns (bool)
    {
        bool hasRole = IAccessControlUpgradeable(collectionAddress).hasRole(
            DEPLOYER_ROLE,
            msg.sender
        );
        return hasRole;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               PRIMARY ROYALTIES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function registerCollectionPrimaryRoyaltyReceivers(
        address collectionAddress,
        RoyaltyReceiver[] memory royaltyReceivers
    ) external isOwner {
        RoyaltiesRegistryState storage state = _getRoyaltiesRegistryState();
        _validateRoyaltyReceivers(royaltyReceivers);

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state._collectionPrimaryRoyaltyReceivers[collectionAddress].push(
                royaltyReceivers[i]
            );
        }
    }

    function registerEditionPrimaryRoyaltyReceivers(
        address collectionAddress,
        uint256 tokenId,
        RoyaltyReceiver[] memory royaltyReceivers
    ) external isOwner {
        RoyaltiesRegistryState storage state = _getRoyaltiesRegistryState();

        _validateRoyaltyReceivers(royaltyReceivers);

        (uint256 editionId, ) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state
            ._editionPrimaryRoyaltyReceivers[collectionAddress][editionId].push(
                    royaltyReceivers[i]
                );
        }
    }

    function registerTokenPrimaryRoyaltyReceivers(
        address collectionAddress,
        uint256 tokenId,
        RoyaltyReceiver[] memory royaltyReceivers
    ) external isOwner {
        RoyaltiesRegistryState storage state = _getRoyaltiesRegistryState();

        _validateRoyaltyReceivers(royaltyReceivers);

        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state
            ._tokenPrimaryRoyaltyReceivers[collectionAddress][editionId][
                tokenNumber
            ].push(royaltyReceivers[i]);
        }
    }

    /// @dev Returns the royalties for the given `tokenId`.
    function primaryRoyaltyInfo(address collectionAddress, uint256 tokenId)
        external
        view
        returns (RoyaltyReceiver[] memory royaltyReceivers)
    {
        RoyaltiesRegistryState storage state = _getRoyaltiesRegistryState();
        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        royaltyReceivers = state._tokenPrimaryRoyaltyReceivers[
            collectionAddress
        ][editionId][tokenNumber];

        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._editionPrimaryRoyaltyReceivers[
                collectionAddress
            ][editionId];
        }
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._collectionPrimaryRoyaltyReceivers[
                collectionAddress
            ];
        }

        return royaltyReceivers;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               SECONDARY ROYALTIES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function registerCollectionSecondaryRoyaltyReceivers(
        address collectionAddress,
        RoyaltyReceiver[] memory royaltyReceivers
    ) external isAuthorized(collectionAddress) {
        RoyaltiesRegistryState storage state = _getRoyaltiesRegistryState();

        _validateRoyaltyReceivers(royaltyReceivers);

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state._collectionSecondaryRoyaltyReceivers[collectionAddress].push(
                royaltyReceivers[i]
            );
        }
    }

    function registerEditionSecondaryRoyaltyReceivers(
        address collectionAddress,
        uint256 tokenId,
        RoyaltyReceiver[] memory royaltyReceivers
    ) external isAuthorized(collectionAddress) {
        RoyaltiesRegistryState storage state = _getRoyaltiesRegistryState();

        _validateRoyaltyReceivers(royaltyReceivers);

        (uint256 editionId, ) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state
            ._editionSecondaryRoyaltyReceivers[collectionAddress][editionId]
                .push(royaltyReceivers[i]);
        }
    }

    function registerTokenSecondaryRoyaltyReceivers(
        address collectionAddress,
        uint256 tokenId,
        RoyaltyReceiver[] memory royaltyReceivers
    ) external isAuthorized(collectionAddress) {
        RoyaltiesRegistryState storage state = _getRoyaltiesRegistryState();

        _validateRoyaltyReceivers(royaltyReceivers);

        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state
            ._tokenSecondaryRoyaltyReceivers[collectionAddress][editionId][
                tokenNumber
            ].push(royaltyReceivers[i]);
        }
    }

    /// @dev for external platforms we always return resale royalties
    function _getRoyaltyReceivers(address collectionAddress, uint256 tokenId)
        internal
        view
        returns (address payable[] memory)
    {
        RoyaltiesRegistryState storage state = _getRoyaltiesRegistryState();
        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        RoyaltyReceiver[] memory royaltyReceivers = state
            ._tokenSecondaryRoyaltyReceivers[collectionAddress][editionId][
                tokenNumber
            ];
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._editionSecondaryRoyaltyReceivers[
                collectionAddress
            ][editionId];
        }
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._collectionSecondaryRoyaltyReceivers[
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
    function _getRoyaltyBPS(address collectionAddress, uint256 tokenId)
        internal
        view
        returns (uint256[] memory)
    {
        RoyaltiesRegistryState storage state = _getRoyaltiesRegistryState();

        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        RoyaltyReceiver[] memory royaltyReceivers = state
            ._tokenSecondaryRoyaltyReceivers[collectionAddress][editionId][
                tokenNumber
            ];
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._editionSecondaryRoyaltyReceivers[
                collectionAddress
            ][editionId];
        }
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._collectionSecondaryRoyaltyReceivers[
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
        RoyaltiesRegistryState storage state = _getRoyaltiesRegistryState();

        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );
        RoyaltyReceiver[] memory royaltyReceivers = state
            ._tokenSecondaryRoyaltyReceivers[collectionAddress][editionId][
                tokenNumber
            ];

        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._editionSecondaryRoyaltyReceivers[
                collectionAddress
            ][editionId];
        }

        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._collectionSecondaryRoyaltyReceivers[
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
            _getRoyaltyBPS(collectionAddress, tokenId)
        );
    }

    /// @dev Foundation
    function getFees(address collectionAddress, uint256 editionId)
        external
        view
        returns (address payable[] memory, uint256[] memory)
    {
        return getRoyalties(collectionAddress, editionId);
    }

    /// @dev Rarible: RoyaltiesV1
    function getFeeBps(address collectionAddress, uint256 tokenId)
        external
        view
        returns (uint256[] memory)
    {
        return _getRoyaltyBPS(collectionAddress, tokenId);
    }

    /// @dev Rarible: RoyaltiesV1
    function getFeeRecipients(address collectionAddress, uint256 editionId)
        external
        view
        returns (address payable[] memory)
    {
        return _getRoyaltyReceivers(collectionAddress, editionId);
    }

    /// @dev Rarible: RoyaltiesV2
    function getRaribleV2Royalties(address collectionAddress, uint256 tokenId)
        external
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

        uint256[] memory bps = _getRoyaltyBPS(collectionAddress, tokenId);

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
        external
        view
        returns (address payable[] memory recipients_, uint256[] memory bps)
    {
        return (
            _getRoyaltyReceivers(collectionAddress, tokenId),
            _getRoyaltyBPS(collectionAddress, tokenId)
        );
    }

    /// @dev CreatorCore - Support for Zora
    function convertBidShares(address collectionAddress, uint256 tokenId)
        external
        view
        returns (address payable[] memory recipients_, uint256[] memory bps)
    {
        return (
            _getRoyaltyReceivers(collectionAddress, tokenId),
            _getRoyaltyBPS(collectionAddress, tokenId)
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
        RoyaltyReceiver[] memory royaltyReceivers
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
    }

    function _calculateTotalRoyalties(RoyaltyReceiver[] memory royaltyReceivers)
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