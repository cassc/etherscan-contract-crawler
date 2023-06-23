// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

import {FairxyzEditionsBaseUpgradeable} from "./FairxyzEditionsBaseUpgradeable.sol";
import {FairxyzEditionsConstants} from "./FairxyzEditionsConstants.sol";

import {IERC2981Upgradeable} from "../interfaces/IERC2981Upgradeable.sol";
import {Edition, EditionCreateParams, EditionMinter, IFairxyzEditions} from "../interfaces/IFairxyzEditions.sol";

import {IFairxyzMintStagesRegistry, Stage} from "../interfaces/IFairxyzMintStagesRegistry.sol";

abstract contract FairxyzEditionsUpgradeable is
    FairxyzEditionsBaseUpgradeable,
    FairxyzEditionsConstants,
    IERC2981Upgradeable,
    IFairxyzEditions
{
    using AddressUpgradeable for address payable;
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    address internal _primarySaleReceiver;

    Royalty internal _defaultRoyalty;

    uint256 private _editionsCount;

    mapping(uint256 => Edition) internal _editions;

    mapping(uint256 => bool) internal _editionDeleted;

    mapping(uint256 => uint256) internal _editionBurnedCount;

    mapping(uint256 => uint256) internal _editionMintedCount;

    mapping(uint256 => mapping(address => EditionMinter))
        private _editionMinters;

    mapping(uint256 => Royalty) internal _editionRoyalty;

    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        private _editionStageMints;

    mapping(uint256 => string) internal _editionURI;

    modifier onlyDefaultAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier onlyAirdropRoles() {
        if (!hasRole(CREATOR_ROLE, msg.sender)) {
            _checkRole(EXTERNAL_MINTER_ROLE);
        }
        _;
    }

    modifier onlyCreator() {
        _checkRole(CREATOR_ROLE);
        _;
    }

    modifier onlyExistingEdition(uint256 editionId) {
        if (!_editionExists(editionId)) revert EditionDoesNotExist();
        _;
    }

    modifier onlyValidRoyaltyFraction(uint256 royaltyFraction) {
        if (royaltyFraction > ROYALTY_DENOMINATOR)
            revert InvalidRoyaltyFraction();
        _;
    }

    receive() external payable virtual {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        uint256 fairxyzMintFee_,
        address fairxyzReceiver_,
        address fairxyzSigner_,
        address fairxyzStagesRegistry_,
        uint256 maxEditionSize_,
        uint256 maxRecipientsPerAirdrop_
    )
        FairxyzEditionsConstants(
            fairxyzMintFee_,
            fairxyzReceiver_,
            fairxyzSigner_,
            fairxyzStagesRegistry_,
            maxEditionSize_,
            maxRecipientsPerAirdrop_
        )
    {
        _disableInitializers();
    }

    // * INITIALIZERS * //

    function __FairxyzEditions_init(address owner_) internal onlyInitializing {
        __FairxyzEditions_init_unchained(owner_);
    }

    function __FairxyzEditions_init_unchained(
        address owner_
    ) internal onlyInitializing {
        if (owner_ == address(0)) {
            revert ZeroAddress();
        }

        _primarySaleReceiver = owner_;
        _transferOwnership(owner_);
    }

    // * PUBLIC * //

    /**
     * @dev See {IFairxyzEditions-mintEdition}.
     */
    function mintEdition(
        uint256 editionId,
        address recipient,
        uint256 quantity,
        uint40 signatureNonce,
        uint256 signatureMaxMints,
        bytes memory signature
    ) external payable override whenNotPaused {
        _checkMintSignature(
            editionId,
            recipient,
            quantity,
            signatureNonce,
            signatureMaxMints,
            signature
        );

        (uint256 stageIndex, Stage memory stage) = _stagesRegistry()
            .viewActiveStage(address(this), editionId);

        uint256 costPerToken = stage.price + FAIRXYZ_MINT_FEE;

        if (msg.value != quantity * costPerToken) {
            revert IncorrectEthValue();
        }

        EditionMinter memory editionMinter = _editionMinters[editionId][
            recipient
        ];

        uint256 recipientStageMints = _editionStageMints[editionId][stageIndex][
            recipient
        ];

        uint256 editionMintedTotal = _editionMintedCount[editionId];

        uint256 allowedQuantity = _calculateAllowedMintQuantity(
            quantity,
            editionId,
            editionMintedTotal,
            stage,
            editionMinter.mintedCount,
            recipientStageMints,
            signatureMaxMints
        );

        unchecked {
            _editionMinters[editionId][recipient] = EditionMinter(
                editionMinter.mintedCount + uint40(allowedQuantity),
                signatureNonce
            );

            _editionStageMints[editionId][stageIndex][
                recipient
            ] += allowedQuantity;
            _editionMintedCount[editionId] += allowedQuantity;

            _mintEditionTokens(
                recipient,
                editionId,
                allowedQuantity,
                editionMintedTotal
            );

            emit EditionStageMint(
                editionId,
                stageIndex,
                recipient,
                allowedQuantity,
                editionMintedTotal + allowedQuantity
            );

            payable(FAIRXYZ_RECEIVER_ADDRESS).sendValue(
                FAIRXYZ_MINT_FEE * allowedQuantity
            );

            // refund for excess quantity not allowed to mint
            if (allowedQuantity < quantity) {
                uint256 refundAmount = (quantity - allowedQuantity) *
                    costPerToken;
                payable(msg.sender).sendValue(refundAmount);
            }
        }
    }

    /**
     * @dev See {IFairxyzEditions-editionTotalSupply}.
     */
    function editionTotalSupply(
        uint256 editionId
    ) public view virtual override returns (uint256) {
        return _editionMintedCount[editionId] - _editionBurnedCount[editionId];
    }

    /**
     * @dev See {IFairxyzEditions-getEdition}.
     */
    function getEdition(
        uint256 editionId
    )
        public
        view
        virtual
        onlyExistingEdition(editionId)
        returns (Edition memory)
    {
        return _editions[editionId];
    }

    /**
     * @dev See {IFairxyzEditions-totalSupply}.
     */
    function totalSupply()
        external
        view
        virtual
        override
        returns (uint256 supply)
    {
        for (uint256 i = 1; i <= _editionsCount; ) {
            supply += editionTotalSupply(i);
            unchecked {
                ++i;
            }
        }
    }

    // * ADMIN * //

    /**
     * @notice Airdrop Tokens for a Single Edition to Multiple Wallets
     * @dev See {IFairEditionsUpgradeable-airdropEdition}.
     *
     * Requirements:
     * - the edition must exist
     * - number of recipients must not be greater than `MAX_RECIPIENTS_PER_AIRDROP`
     * - quantity must not be greater than `MAX_MINTS_PER_TRANSACTION`
     *
     * Emits an {EditionAirdrop} event.
     */
    function airdropEdition(
        uint256 editionId,
        uint256 quantity,
        address[] memory recipients
    )
        external
        virtual
        override
        onlyAirdropRoles
        onlyExistingEdition(editionId)
        whenNotPaused
    {
        uint256 numberOfRecipients = recipients.length;
        if (
            numberOfRecipients == 0 ||
            numberOfRecipients > _maxRecipientsPerAirdrop()
        ) revert InvalidNumberOfRecipients();

        // check and update available supply
        uint256 totalQuantity = numberOfRecipients * quantity;
        uint256 editionMintedTotal = _editionMintedCount[editionId];

        if (
            totalQuantity + editionMintedTotal >
            _editionMintLimit(_editions[editionId].maxSupply)
        ) revert NotEnoughSupplyRemaining();

        _editionMintedCount[editionId] = editionMintedTotal + totalQuantity;

        uint256 i;
        do {
            address recipient = recipients[i];
            _mintEditionTokens(
                recipient,
                editionId,
                quantity,
                editionMintedTotal
            );

            unchecked {
                editionMintedTotal += quantity;
                ++i;
            }
        } while (i < numberOfRecipients);

        emit EditionAirdrop(
            editionId,
            _stagesRegistry().viewLatestStageIndex(address(this), editionId), // even though airdrops do not count towards stage mints, it is useful to know at what stage it occurred
            recipients,
            quantity,
            editionMintedTotal
        );
    }

    /**
     * @notice Add a New Edition
     * @dev See {IFairxyzEditions-createEdition}.
     */
    function createEditions(
        EditionCreateParams[] calldata editions
    ) external virtual override onlyCreator {
        _batchCreateEditionsWithStages(editions);
    }

    /**
     * @notice Delete Edition
     * @dev See {IFairxyzEditions-deleteEdition}.
     */
    function deleteEdition(
        uint256 editionId
    ) external virtual override onlyCreator onlyExistingEdition(editionId) {
        if (_editionMintedCount[editionId] > 0) revert EditionAlreadyMinted();
        _deleteEdition(editionId);
    }

    /**
     * @notice Disable Signature Requirement for an Edition
     * @dev See {IFairxyzEditions-releaseEditionSignature}.
     */
    function releaseEditionSignature(
        uint256 editionId
    ) external virtual override onlyCreator onlyExistingEdition(editionId) {
        if (_editions[editionId].signatureReleased)
            revert EditionSignatureAlreadyReleased();
        _editions[editionId].signatureReleased = true;
        emit EditionSignatureReleased(editionId);
    }

    /**
     * @notice Set Default Royalty
     * @dev See {IFairxyzEditions-setDefaultRoyalty}.
     *
     * Emits a {DefaultRoyalty} event.
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 royaltyFraction
    ) external virtual override onlyDefaultAdmin {
        _setDefaultRoyalty(receiver, royaltyFraction);
    }

    /**
     * @dev See {IFairxyzEditions-setEditionBurnable}.
     *
     * Emits an {EditionBurnable} event.
     */
    function setEditionBurnable(
        uint256 editionId,
        bool burnable
    ) external virtual override onlyCreator onlyExistingEdition(editionId) {
        _editions[editionId].burnable = burnable;
        emit EditionBurnable(editionId, burnable);
    }

    /**
     * @notice Set Edition Maximum Mints Per Wallet
     * @dev See {IFairxyzEditions-setEditionMaxMintsPerWallet}.
     */
    function setEditionMaxMintsPerWallet(
        uint256 editionId,
        uint40 maxMintsPerWallet
    ) external virtual override onlyCreator onlyExistingEdition(editionId) {
        _editions[editionId].maxMintsPerWallet = maxMintsPerWallet;
        emit EditionMaxMintsPerWallet(editionId, maxMintsPerWallet);
    }

    /**
     * @notice Set Edition Maximum Supply
     * @dev See {IFairxyzEditions-setEditionMaxSupply}.
     *
     * Requirements:
     *
     * - the new max supply can't be greater than the current max supply
     * - the new max supply can't be less than the number of tokens already minted
     * - the new max supply can't be less than scheduled in current/upcoming mint stages
     */
    function setEditionMaxSupply(
        uint256 editionId,
        uint40 maxSupply
    ) external virtual override onlyCreator onlyExistingEdition(editionId) {
        if (maxSupply == 0) revert EditionSupplyCanOnlyBeReduced();
        if (maxSupply >= _editionMintLimit(_editions[editionId].maxSupply))
            revert EditionSupplyCanOnlyBeReduced();

        // check that max supply is not less than minted count
        // it's possible for the owner to airdrop more than stage phase limits so need to be checked separately
        if (maxSupply < _editionMintedCount[editionId])
            revert EditionSupplyLessThanMintedCount();

        (, Stage memory finalStage) = _stagesRegistry().viewFinalStage(
            address(this),
            editionId
        );

        // if final stage has not yet ended, check that max supply is not less than final stage phaseLimit
        if (
            finalStage.startTime > 0 && // if final stage startTime is 0, it means there is no final stage
            (finalStage.endTime >= block.timestamp || finalStage.endTime == 0) // if final stage endTime is 0, it means it never ends
        ) {
            // if final stage phaseLimit is 0, it means there is no limit and supply can't be reduced
            if (finalStage.phaseLimit == 0) {
                revert EditionSupplyLessThanScheduledStagesPhaseLimit();
            }

            if (maxSupply < finalStage.phaseLimit) {
                revert EditionSupplyLessThanScheduledStagesPhaseLimit();
            }
        }

        _editions[editionId].maxSupply = maxSupply;
        emit EditionMaxSupply(editionId, maxSupply);
    }

    /**
     * @notice Set Edition Royalties
     * @dev See {IFairxyzEditions-setEditionRoyalty}.
     */
    function setEditionRoyalty(
        uint256 editionId,
        address receiver,
        uint96 royaltyFraction
    )
        external
        virtual
        override
        onlyCreator
        onlyExistingEdition(editionId)
        onlyValidRoyaltyFraction(royaltyFraction)
    {
        if (receiver == address(0)) {
            delete _editionRoyalty[editionId];
            emit EditionRoyalty(editionId, address(0), 0);
            return;
        }

        _editionRoyalty[editionId] = Royalty(receiver, royaltyFraction);
        emit EditionRoyalty(editionId, receiver, royaltyFraction);
    }

    /**
     * @notice Set Edition Mint Stages
     * @dev See {IFairxyzEditions-setEditionStages}.
     * @dev Allows the stages admin to set new stages for an existing edition.
     *
     * Requirements:
     *
     * - The edition must already exist.
     * - The new stages phase limits must greater than the number of tokens already minted for the edition.
     * - The new stages phase limits must be less than or equal to the max supply of the edition.
     */
    function setEditionStages(
        uint256 editionId,
        uint256 fromIndex,
        Stage[] calldata stages
    ) external virtual override onlyCreator onlyExistingEdition(editionId) {
        if (stages.length == 0) {
            _stagesRegistry().cancelStages(address(this), editionId, fromIndex);
        } else {
            _stagesRegistry().setStages(
                address(this),
                editionId,
                fromIndex,
                stages,
                _editionMintedCount[editionId],
                _editions[editionId].maxSupply
            );
        }
    }

    /**
     * @notice Set Edition Metadata URI
     * @dev See {IFairxyzEditions-setEditionURI}.
     */
    function setEditionURI(
        uint256 editionId,
        string calldata uri
    ) external virtual override onlyCreator onlyExistingEdition(editionId) {
        _setEditionURI(editionId, uri);

        if (_editionMintedCount[editionId] > 0)
            _emitMetadataUpdateEvent(editionId, uri);
    }

    /**
     * @notice Set Primary Sale Receiver
     * @dev See {IFairxyzEditions-setPrimarySaleReceiver}.
     *
     * Emits a {PrimarySaleReceiver} event.
     */
    function setPrimarySaleReceiver(
        address primarySaleReceiver
    ) external virtual override onlyDefaultAdmin {
        if (primarySaleReceiver == address(0)) revert ZeroAddress();

        _primarySaleReceiver = primarySaleReceiver;
        emit PrimarySaleReceiver(primarySaleReceiver);
    }

    /**
     * @dev See {IFairxyzEditions-pause}.
     */
    function pause() external virtual override onlyDefaultAdmin {
        _pause();
    }

    /**
     * @dev See {IFairxyzEditions-unpause}.
     */
    function unpause() external virtual override onlyDefaultAdmin {
        _unpause();
    }

    /**
     * @dev See {IFairxyzEditions-withdraw}.
     */
    function withdraw() external override onlyDefaultAdmin {
        payable(_primarySaleReceiver).sendValue(address(this).balance);
    }

    // * OWNER * //

    /**
     * @dev See {IFairxyzEditions-grantDefaultAdmin}.
     */
    function grantDefaultAdmin(
        address admin
    ) external virtual override onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    // * INTERNAL * //

    /**
     * @dev Creates multiple editions and stores the mint stages for them if provided.
     *
     * @param editions the editions to create
     */
    function _batchCreateEditionsWithStages(
        EditionCreateParams[] calldata editions
    ) internal {
        uint256 editionsCount = _editionsCount;

        unchecked {
            for (uint256 i; i < editions.length; ) {
                // check edition supply is valid
                if (editions[i].edition.maxSupply > MAX_EDITION_SIZE) {
                    revert EditionSupplyTooLarge();
                }

                editionsCount++;

                // store the edition and emit the created event
                Edition memory edition = editions[i].edition;
                _editions[editionsCount] = edition;

                emit EditionCreated(
                    editionsCount,
                    editions[i].externalId,
                    edition
                );

                _setEditionURI(editionsCount, editions[i].uri);

                // set the initial minting schedule if given for the edition
                if (editions[i].mintStages.length > 0) {
                    _stagesRegistry().setStages(
                        address(this),
                        editionsCount,
                        0,
                        editions[i].mintStages,
                        0,
                        edition.maxSupply
                    );
                }

                ++i;
            }
        }

        _editionsCount = editionsCount;
    }

    /**
     * @dev Calculates the allowed mint quantity based on the requested quantity and current recipient, edition and stage data
     * @dev Reverts if the calculated quantity is zero
     *
     * @param requestedQuantity the desired quantity
     * @param editionId the ID of the edition to mint from
     * @param editionMintedTotal the total number of tokens already minted for the edition
     * @param stage the stage data
     * @param recipientEditionMints the number of tokens already minted to the recipient for the edition
     * @param recipientStageMints the number of tokens already minted to the recipient for the stage
     * @param signatureMaxMints an additional maximum mints restriction encoded in the signature, specific to the recipient at the time of minting
     */
    function _calculateAllowedMintQuantity(
        uint256 requestedQuantity,
        uint256 editionId,
        uint256 editionMintedTotal,
        Stage memory stage,
        uint256 recipientEditionMints,
        uint256 recipientStageMints,
        uint256 signatureMaxMints
    ) internal view virtual returns (uint256 quantity) {
        quantity = requestedQuantity;

        // recipient stage mints (including previously minted) cannot exceed signature max mints per wallet
        if (signatureMaxMints > 0) {
            if (recipientStageMints >= signatureMaxMints) {
                revert RecipientAllowanceUsed();
            }
            uint256 recipientRemainingMints = signatureMaxMints -
                recipientStageMints;
            if (quantity > recipientRemainingMints) {
                quantity = recipientRemainingMints;
            }
        }

        // recipient stage mints cannot exceed stage mints per wallet
        if (stage.mintsPerWallet > 0) {
            if (recipientStageMints >= stage.mintsPerWallet) {
                revert RecipientStageAllowanceUsed();
            }
            uint256 recipientStageRemainingMints = stage.mintsPerWallet -
                recipientStageMints;
            if (quantity > recipientStageRemainingMints) {
                quantity = recipientStageRemainingMints;
            }
        }

        Edition memory edition = getEdition(editionId);

        // recipient cannot exceed edition max mints per wallet
        if (edition.maxMintsPerWallet > 0) {
            if (recipientEditionMints >= edition.maxMintsPerWallet) {
                revert RecipientEditionAllowanceUsed();
            }
            uint256 recipientEditionRemainingMints = edition.maxMintsPerWallet -
                recipientEditionMints;
            if (quantity > recipientEditionRemainingMints) {
                quantity = recipientEditionRemainingMints;
            }
        }

        uint256 stagePhaseLimit = stage.phaseLimit;
        if (stagePhaseLimit == 0) {
            stagePhaseLimit = MAX_EDITION_SIZE;
        }

        // quantity cannot exceed stage remaining mints
        if (editionMintedTotal >= stagePhaseLimit) {
            revert StageSoldOut();
        }
        uint256 stageRemainingMints = stagePhaseLimit - editionMintedTotal;
        if (quantity > stageRemainingMints) {
            quantity = stageRemainingMints;
        }
    }

    /**
     * @dev Checks the mint signature is valid and also compares nonce to the state of the contract for the recipient.
     *
     * @param editionId the ID of the edition being minted
     * @param recipient the address of the intended recipient of minted tokens
     * @param quantity the requested quantity to mint
     * @param nonce the blocknumber at the time the signature was generated, used to determine reuse/expiry of the signature
     * @param maxMints an additional limitation on the number of max mints for the recipient and stage for this particular signature (0 is unlimited)
     * @param signature the signature to check
     */
    function _checkMintSignature(
        uint256 editionId,
        address recipient,
        uint256 quantity,
        uint256 nonce,
        uint256 maxMints,
        bytes memory signature
    ) internal virtual {
        if (_editions[editionId].signatureReleased) {
            return;
        }

        if (nonce > block.number) {
            revert InvalidSignatureNonce();
        }

        if (nonce + SIGNATURE_VALID_BLOCKS < block.number) {
            revert SignatureExpired();
        }

        if (nonce <= _editionMinters[editionId][recipient].lastUsedNonce) {
            revert SignatureAlreadyUsed();
        }

        bytes32 messageHash = _hashMintParams(
            editionId,
            recipient,
            quantity,
            nonce,
            maxMints
        );

        // Ensure the recovered address from the signature is the Fairxyz.xyz signer address
        if (messageHash.recover(signature) != FAIRXYZ_FAIRXYZ_SIGNER_ADDRESS)
            revert InvalidSignature();
    }

    /**
     * @dev Marks an edition as deleted.
     * @dev Deleted editions will be considered as none existent.
     *
     * Requirements:
     * - the edition must exist / not have already been deleted.
     *
     * Emits an {EditionDeleted} event.
     *
     * @param editionId the ID of the edition
     */
    function _deleteEdition(uint256 editionId) internal virtual {
        _editionDeleted[editionId] = true;
        emit EditionDeleted(editionId);
    }

    /**
     * @dev Checks for the existence of an edition based on created and not deleted edition IDs.
     *
     * @param editionId the ID of the edition to check
     */
    function _editionExists(uint256 editionId) internal view returns (bool) {
        if (
            editionId == 0 ||
            editionId > _editionsCount ||
            _editionDeleted[editionId]
        ) return false;
        return true;
    }

    /**
     * @dev Calculate the mint limit for an edition.
     *
     * @param editionMaxSupply the max supply of an edition
     *
     * @return limit
     */
    function _editionMintLimit(
        uint256 editionMaxSupply
    ) internal view virtual returns (uint256 limit) {
        if (editionMaxSupply == 0) {
            limit = MAX_EDITION_SIZE;
        } else {
            limit = editionMaxSupply;
        }
    }

    /**
     * @dev Emits metadata update event used by marketplaces to refresh token metadata.
     * @dev To be overridden by specific token implementation.
     *
     * - ERC-721 should emit ERC-4906 (Batch)MetadataUpdate event.
     * - ERC-1155 should emit the standard URI event.
     *
     * @param editionId the ID of the edition
     * @param uri the new URI
     */
    function _emitMetadataUpdateEvent(
        uint256 editionId,
        string memory uri
    ) internal virtual;

    /**
     * @dev Regenerates the expected signature digest for the mint params.
     */
    function _hashMintParams(
        uint256 editionId,
        address recipient,
        uint256 quantity,
        uint256 nonce,
        uint256 maxMints
    ) internal view returns (bytes32) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    EIP712_EDITION_MINT_TYPE_HASH,
                    editionId,
                    recipient,
                    quantity,
                    nonce,
                    maxMints
                )
            )
        );
        return digest;
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     */
    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPE_HASH,
                EIP712_NAME_HASH,
                EIP712_VERSION_HASH,
                block.chainid,
                address(this)
            )
        );

        return ECDSAUpgradeable.toTypedDataHash(domainSeparator, structHash);
    }

    /**
     * @dev Returns the maximum number of recipients that can be minted to in a single airdrop.
     */
    function _maxRecipientsPerAirdrop()
        internal
        view
        virtual
        returns (uint256)
    {
        return MAX_RECIPIENTS_PER_AIRDROP;
    }

    /**
     * @dev Mints `quantity` tokens of edition `editionId` to `recipient`.
     * @dev Intended to be overridden by inheriting contract which implements a particular token standard.
     *
     * @param recipient the address the tokens should be minted to
     * @param editionId the ID of the edition to mint tokens of
     * @param quantity the quantity of tokens to mint
     * @param editionMintedCount the number of tokens already minted for the edition
     */
    function _mintEditionTokens(
        address recipient,
        uint256 editionId,
        uint256 quantity,
        uint256 editionMintedCount
    ) internal virtual;

    /**
     * @dev Sets the default royalty details for the collection.
     *
     * @param receiver the address royalty payments should be sent to
     * @param royaltyFraction the numerator used to calculate the royalty percentage of a sale
     */
    function _setDefaultRoyalty(
        address receiver,
        uint96 royaltyFraction
    ) internal virtual onlyValidRoyaltyFraction(royaltyFraction) {
        if (receiver == address(0)) {
            delete _defaultRoyalty;
            emit DefaultRoyalty(address(0), 0);
            return;
        }

        _defaultRoyalty = Royalty(receiver, royaltyFraction);
        emit DefaultRoyalty(receiver, royaltyFraction);
    }

    function _setEditionURI(
        uint256 editionId,
        string memory uri
    ) internal virtual {
        if (bytes(uri).length == 0) {
            revert InvalidURI();
        }

        _editionURI[editionId] = uri;
        emit EditionURI(editionId, uri);
    }

    /**
     * @dev Returns the stages registry used for managing mint stages.
     */
    function _stagesRegistry()
        internal
        view
        virtual
        returns (IFairxyzMintStagesRegistry)
    {
        return IFairxyzMintStagesRegistry(FAIRXYZ_STAGES_REGISTRY);
    }

    // * OVERRIDES * //

    /**
     * @dev See {IERC165Upgradeable-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(FairxyzEditionsBaseUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IFairxyzEditions).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            FairxyzEditionsBaseUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IAccessControlUpgradeable-_checkRole}.
     * @dev Overriden to supersede any access control roles with contract ownership.
     */
    function _checkRole(bytes32 role) internal view virtual override {
        if (_msgSender() != owner()) _checkRole(role, _msgSender());
    }

    // * PRIVATE * //

    uint256[39] private __gap;
}