// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

import {FairxyzEditionsUpgradeable} from "./FairxyzEditionsUpgradeable.sol";
import {Fairxyz1155Upgradeable} from "../ERC1155/Fairxyz1155Upgradeable.sol";
import {FairxyzOperatorFiltererUpgradeable} from "../OperatorFilterer/FairxyzOperatorFiltererUpgradeable.sol";

import {EditionCreateParams} from "../interfaces/IFairxyzEditions.sol";
import {IFairxyz1155Editions} from "../interfaces/IFairxyz1155Editions.sol";
import {Stage} from "../interfaces/IFairxyzMintStagesRegistry.sol";

/**
 * @title Fair.xyz 1155 Editions
 * @author Fair.xyz Developers
 *
 * @dev This contract is the ERC-1155 implementation for the Fair.xyz Editions Collections.
 * @dev It inherits the FairxyzEditionsUpgradeable contract, adding ERC-1155 specific functionality.
 * @dev It also inherits the FairxyzOperatorFiltererUpgradeable contract, adding operator filtering functionality for token approvals and transfers.
 */
contract Fairxyz1155Editions is
    Fairxyz1155Upgradeable,
    FairxyzOperatorFiltererUpgradeable,
    IFairxyz1155Editions,
    FairxyzEditionsUpgradeable
{
    // Token name
    string public name;

    // Token symbol
    string public symbol;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        uint256 fairxyzMintFee_,
        address fairxyzReceiver_,
        address fairxyzSigner_,
        address fairxyzStagesRegistry_,
        uint256 maxRecipientsPerAirdrop_,
        address operatorFilterRegistry_,
        address operatorFilterSubscription_
    )
        FairxyzEditionsUpgradeable(
            fairxyzMintFee_,
            fairxyzReceiver_,
            fairxyzSigner_,
            fairxyzStagesRegistry_,
            type(uint40).max,
            maxRecipientsPerAirdrop_
        )
        FairxyzOperatorFiltererUpgradeable(
            operatorFilterRegistry_,
            operatorFilterSubscription_
        )
    {
        _disableInitializers();
    }

    /**
     * @notice Initialise the collection.
     *
     * @param name_ The name of the collection.
     * @param symbol_ The symbol of the collection.
     * @param owner_ The address which should own the contract after initialization.
     * @param defaultRoyalty_ The default royalty fraction/percentage for the collection.
     * @param editions_ Initial editions to create.
     * @param operatorFilterEnabled_ Whether operator filtering should be enabled.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint96 defaultRoyalty_,
        EditionCreateParams[] calldata editions_,
        bool operatorFilterEnabled_
    ) external initializer {
        __Fairxyz1155_init();
        __FairxyzEditions_init(owner_);
        __FairxyzOperatorFilterer_init(operatorFilterEnabled_);

        _batchCreateEditionsWithStages(editions_);

        if (defaultRoyalty_ > 0) {
            _setDefaultRoyalty(owner_, defaultRoyalty_);
        }

        name = name_;
        symbol = symbol_;
    }

    // * PUBLIC * //

    /**
     * @dev See {IFairxyz1155Editions-burn}.
     */
    function burn(
        address from,
        uint256 editionId,
        uint256 amount
    ) external override {
        address operator = msg.sender;
        if (operator != from && !isApprovedForAll(from, operator))
            revert NotApprovedOrOwner();

        if (!_editions[editionId].burnable) revert NotBurnable();
        _burn(from, editionId, amount);
        _editionBurnedCount[editionId] += amount;
    }

    // * OVERRIDES * //

    /**
     * @dev See {IERC2981Upgradeable-royaltyInfo}.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        Royalty memory royalty = _editionRoyalty[tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyalty;
        }

        receiver = royalty.receiver;
        royaltyAmount =
            (salePrice * royalty.royaltyFraction) /
            ROYALTY_DENOMINATOR;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     * @dev Modified to check operator against Operator Filter Registry.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC165Upgradeable-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(Fairxyz1155Upgradeable, FairxyzEditionsUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IFairxyz1155Editions).interfaceId ||
            Fairxyz1155Upgradeable.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataUpgradeable-uri}.
     */
    function uri(uint256 id) external view override returns (string memory) {
        if (!_editionExists(id)) return "";
        return _editionURI[id];
    }

    /**
     * @dev See {Fairxyz1155Upgradeable-_beforeTokenTransfer}.
     * @dev Modified to check `msg.sender` against Operator Filter Registry.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal virtual override onlyAllowedOperator(operator, from) {
        // we only want to implement soulbound guard if the token is being transferred between two non-zero addresses
        if (from == address(0) || to == address(0)) {
            return;
        }

        for (uint256 i; i < ids.length; ) {
            uint256 id = ids[i];
            if (_editions[id].soulbound) {
                revert NotTransferable();
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {FairxyzEditionsUpgradeable-_emitMetadataUpdateEvent}.
     */
    function _emitMetadataUpdateEvent(
        uint256 editionId,
        string memory editionURI
    ) internal override {
        emit URI(editionURI, editionId);
    }

    /**
     * @dev See {OperatorFiltererUpgradeable-_isOperatorFilterAdmin}.
     */
    function _isOperatorFilterAdmin(
        address sender
    ) internal view virtual override returns (bool) {
        return sender == owner() || hasRole(DEFAULT_ADMIN_ROLE, sender);
    }

    /**
     * @dev See {FairxyzEditionsUpgradeable-_mintEditionTokens}.
     */
    function _mintEditionTokens(
        address recipient,
        uint256 editionId,
        uint256 quantity,
        uint256
    ) internal override {
        if (quantity == 0) revert InvalidMintQuantity();

        _mint(recipient, editionId, quantity, "");
    }
}