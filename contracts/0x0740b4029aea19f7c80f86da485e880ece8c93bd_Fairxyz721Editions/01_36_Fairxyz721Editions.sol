// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {FairxyzEditionsUpgradeable} from "./FairxyzEditionsUpgradeable.sol";
import {Fairxyz721Upgradeable} from "../ERC721/Fairxyz721Upgradeable.sol";
import {FairxyzOperatorFiltererUpgradeable} from "../OperatorFilterer/FairxyzOperatorFiltererUpgradeable.sol";

import {EditionCreateParams} from "../interfaces/IFairxyzEditions.sol";
import {IFairxyz721Editions} from "../interfaces/IFairxyz721Editions.sol";
import {Stage} from "../interfaces/IFairxyzMintStagesRegistry.sol";

/**
 * @title Fair.xyz 721 Editions
 * @author Fair.xyz Developers
 *
 * @dev This contract is the ERC-721 implementation for the Fair.xyz Editions Collections.
 * @dev It overrides the FairxyzEditionsUpgradeable contract to add ERC-721 specific functionality.
 * @dev It overrides the Fairxyz721Upgradeable contract to add Editions specific, optimised batch minting functionality.
 * @dev It also inherits the FairxyzOperatorFiltererUpgradeable contract, adding operator filtering functionality for token approvals and transfers.
 */
contract Fairxyz721Editions is
    Fairxyz721Upgradeable,
    FairxyzOperatorFiltererUpgradeable,
    IFairxyz721Editions,
    FairxyzEditionsUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    uint256 internal constant EDITION_RANGE_SIZE = 1_000_000_000;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 internal immutable MAX_MINTS_PER_TRANSACTION;

    mapping(uint256 => bool) internal _tokenBurned;
    mapping(uint256 => address) internal _tokenMinter;
    mapping(uint256 => Royalty) internal _tokenRoyalty;
    mapping(uint256 => string) internal _tokenURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        uint256 fairxyzMintFee_,
        address fairxyzReceiver_,
        address fairxyzSigner_,
        address fairxyzStagesRegistry_,
        uint256 maxMintsPerTransaction_,
        uint256 maxRecipientsPerAirdrop_,
        address operatorFilterRegistry_,
        address operatorFilterSubscription_
    )
        FairxyzEditionsUpgradeable(
            fairxyzMintFee_,
            fairxyzReceiver_,
            fairxyzSigner_,
            fairxyzStagesRegistry_,
            EDITION_RANGE_SIZE - 1,
            maxRecipientsPerAirdrop_
        )
        FairxyzOperatorFiltererUpgradeable(
            operatorFilterRegistry_,
            operatorFilterSubscription_
        )
    {
        MAX_MINTS_PER_TRANSACTION = maxMintsPerTransaction_;
        _disableInitializers();
    }

    /**
     * @notice Initialise the collection.
     *
     * @param name_ The collection ERC721 token name.
     * @param symbol_ The collection ERC721 token symbol.
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
        __Fairxyz721_init(name_, symbol_);
        __FairxyzEditions_init(owner_);

        __FairxyzOperatorFilterer_init(operatorFilterEnabled_);

        _batchCreateEditionsWithStages(editions_);

        if (defaultRoyalty_ > 0) {
            _setDefaultRoyalty(owner_, defaultRoyalty_);
        }
    }

    // * PUBLIC * //

    /**
     * @dev See {IFairxyz721Editions-burn}.
     */
    function burn(uint256 tokenId) external override {
        if (!_isApprovedOrOwner(msg.sender, tokenId))
            revert NotApprovedOrOwner();

        uint256 editionId = _tokenEditionId(tokenId);
        if (!_editions[editionId].burnable) revert NotBurnable();

        _burn(tokenId);
        _tokenBurned[tokenId] = true;
        _editionBurnedCount[editionId]++;
    }

    // * ADMIN * //

    /**
     * @dev See {IFairxyz721Editions-setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 royaltyFraction
    ) external override onlyCreator {
        _setTokenRoyalty(tokenId, receiver, royaltyFraction);
    }

    /**
     * @dev See {IFairxyz721Editions-setTokenURI}.
     */
    function setTokenURI(
        uint256 tokenId,
        string calldata uri
    ) external override onlyCreator {
        _tokenURI[tokenId] = uri;
        if (_exists(tokenId)) emit MetadataUpdate(tokenId);
    }

    // * INTERNAL * //

    /**
     * @dev Calculates the number after which the token IDs in a specific edition start.
     *
     * @param editionId the ID of the edition
     */
    function _editionRangeStart(
        uint256 editionId
    ) internal pure returns (uint256) {
        return editionId * EDITION_RANGE_SIZE;
    }

    /**
     * @dev Sets token royalty details, which overrides the edition/default if receiver is not `address(0)`
     *
     * @param tokenId the ID of the token to update
     * @param receiver the address royalty payments should be sent to
     * @param royaltyFraction the numerator used to calculate the royalty percentage of a sale
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 royaltyFraction
    ) internal onlyValidRoyaltyFraction(royaltyFraction) {
        if (receiver == address(0)) {
            delete _tokenRoyalty[tokenId];
            emit TokenRoyalty(tokenId, address(0), 0);
            return;
        }

        _tokenRoyalty[tokenId] = Royalty(receiver, royaltyFraction);
        emit TokenRoyalty(tokenId, receiver, royaltyFraction);
    }

    /**
     * @dev calculates the edition ID for a given token ID
     * @dev reverts if the token ID is invalid (never possible)
     * @dev does not revert if the token ID is possible but does not exist
     *
     * @param tokenId the ID of the token to get the edition ID for
     *
     * @return editionId the ID of the edition that the token belongs to
     */
    function _tokenEditionId(
        uint256 tokenId
    ) internal pure virtual returns (uint256 editionId) {
        if (tokenId < EDITION_RANGE_SIZE) revert TokenDoesNotExist();
        if (tokenId % EDITION_RANGE_SIZE == 0) revert TokenDoesNotExist();
        return tokenId / EDITION_RANGE_SIZE;
    }

    // * OVERRIDES * //

    /**
     * @dev See {IERC721-approve}.
     * @dev Modified to check operator against Operator Filter Registry.
     */
    function approve(
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(to) {
        super.approve(to, tokenId);
    }

    /**
     * @dev See {IERC2981Upgradeable-royaltyInfo}.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) public view override returns (address receiver, uint256 royaltyAmount) {
        Royalty memory royalty = _tokenRoyalty[tokenId];

        if (royalty.receiver == address(0)) {
            uint256 editionId = _tokenEditionId(tokenId);
            royalty = _editionRoyalty[editionId];

            if (royalty.receiver == address(0)) {
                royalty = _defaultRoyalty;
            }
        }

        receiver = royalty.receiver;
        royaltyAmount =
            (salePrice * royalty.royaltyFraction) /
            ROYALTY_DENOMINATOR;
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
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
        override(Fairxyz721Upgradeable, FairxyzEditionsUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IFairxyz721Editions).interfaceId ||
            Fairxyz721Upgradeable.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721MetadataUpgradeable-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        string memory uri = _tokenURI[tokenId];

        if (bytes(uri).length == 0) {
            uint256 editionId = _tokenEditionId(tokenId);

            return
                string(
                    abi.encodePacked(
                        _editionURI[editionId],
                        (tokenId % EDITION_RANGE_SIZE).toString()
                    )
                );
        }

        return uri;
    }

    /**
     * @dev See {Fairxyz721Upgradeable-_beforeTokenTransfer}.
     * @dev Modified to check `msg.sender` against Operator Filter Registry.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256
    ) internal view override onlyAllowedOperator(msg.sender, from) {
        // we only want to implement soulbound guard if the token is being transferred between two non-zero addresses
        if (from == address(0) || to == address(0)) {
            return;
        }

        if (_editions[_tokenEditionId(firstTokenId)].soulbound) {
            revert NotTransferable();
        }
    }

    /**
     * @dev See {FairxyzEditionsUpgradeable-_emitMetadataUpdateEvent}.
     */
    function _emitMetadataUpdateEvent(
        uint256 editionId,
        string memory
    ) internal override {
        uint256 mintedCount = _editionMintedCount[editionId];
        if (mintedCount == 1) {
            emit MetadataUpdate(_editionRangeStart(editionId) + 1);
        }
        if (_editionMintedCount[editionId] > 1) {
            uint256 rangeStart = _editionRangeStart(editionId);
            emit BatchMetadataUpdate(rangeStart + 1, rangeStart + mintedCount);
            return;
        }
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
        uint256 editionMintedCount
    ) internal override {
        if (quantity == 0 || quantity > MAX_MINTS_PER_TRANSACTION)
            revert InvalidMintQuantity();

        uint256 firstTokenId = _editionRangeStart(editionId) +
            editionMintedCount +
            1;

        _beforeTokenTransfer(address(0), recipient, firstTokenId, quantity);

        _tokenMinter[firstTokenId] = recipient;

        uint256 tokenId = firstTokenId;
        uint256 stop = firstTokenId + quantity;

        do {
            emit Transfer(address(0), recipient, tokenId);

            unchecked {
                ++tokenId;
            }
        } while (tokenId < stop);

        if (recipient.isContract()) {
            tokenId = firstTokenId;
            do {
                require(
                    _checkOnERC721Received(address(0), recipient, tokenId, ""),
                    "ERC721: transfer to non ERC721Receiver implementer"
                );

                unchecked {
                    ++tokenId;
                }
            } while (tokenId < stop);
        }

        __unsafe_increaseBalance(recipient, quantity);

        _afterTokenTransfer(address(0), recipient, firstTokenId, quantity);
    }

    /**
     * @dev See {Fairxyz721Upgradeable-_ownerOf}.
     */
    function _ownerOf(
        uint256 tokenId
    ) internal view override returns (address) {
        if (_tokenBurned[tokenId]) {
            return address(0);
        }

        address tokenOwner = _owners[tokenId];

        if (tokenOwner != address(0)) {
            return tokenOwner;
        }

        uint256 editionId = _tokenEditionId(tokenId);

        uint256 editionRangeStart = _editionRangeStart(editionId);

        // return zero address is the token has not been minted
        if (tokenId > editionRangeStart + _editionMintedCount[editionId]) {
            return address(0);
        }

        while (tokenOwner == address(0) && tokenId > editionRangeStart) {
            tokenOwner = _tokenMinter[tokenId];
            unchecked {
                --tokenId;
            }
        }

        return tokenOwner;
    }
}