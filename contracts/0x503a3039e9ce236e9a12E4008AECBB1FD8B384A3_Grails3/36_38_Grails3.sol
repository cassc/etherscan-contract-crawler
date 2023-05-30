// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

import {ERC721ACommon, ERC721A} from "ethier/erc721/ERC721ACommon.sol";
import {BaseTokenURI} from "ethier/erc721/BaseTokenURI.sol";
import {PRNG} from "ethier/random/PRNG.sol";
import {NextShuffler} from "ethier/random/NextShuffler.sol";
import {OnlyOnce} from "ethier/utils/OnlyOnce.sol";

import {DefaultOperatorFilterer} from
    "operator-filter-registry/DefaultOperatorFilterer.sol";

import {IGrailsRoyaltyRouter} from "grails/season-02/IGrailsRoyaltyRouter.sol";
import {Grails3MintPass} from "grails/season-03/Grails3MintPass.sol";
import {ERC4906} from "grails/season-03/ERC4906.sol";

interface Grails3Events {
    // =========================================================================
    //                    Events
    // =========================================================================

    /**
     * @notice Emitted when the specific Grail is minted.
     */
    event GrailMinted(address indexed receiver, uint8 indexed grailId);
}

/**
 * @title Grails III
 * @author PROOF
 */
contract Grails3 is
    Grails3Events,
    ERC721ACommon,
    BaseTokenURI,
    OnlyOnce,
    DefaultOperatorFilterer,
    ERC4906
{
    using Address for address;
    using Address for address payable;
    using NextShuffler for NextShuffler.State;
    using PRNG for PRNG.Source;

    // =========================================================================
    //                          Errors
    // =========================================================================

    error CallerNotAllowedToRedeemPass();
    error DisallowedByCurrentStage();
    error InvalidGrailId();
    error ParameterLengthMismatch();
    error InvalidFunds(uint256 expected);
    error InsufficientInterface();
    error GrailMintingLimitReached(uint8 grailId);
    error IncorrectNumberOfGrails();

    // =========================================================================
    //                           Types
    // =========================================================================

    /**
     * @notice The different stages of the Grails III contract.
     * @dev Some methods are only accessible for some stages. See also the
     * `Steering` section for more information.
     */
    enum Stage {
        Closed,
        Open
    }

    /**
     * @notice Each minted token corresponds to an edition of a Grail.
     * @dev See also {_grailByTokenId}.
     */
    struct Grail {
        uint8 id;
        uint16 edition;
        uint16 variant;
    }

    /**
     * @notice The different types of Grails in season 3.
     */
    enum GrailType {
        LimitedEdition,
        LimitedSeries
    }

    /**
     * @notice Struct to store the types and other config of individual grails.
     * @dev We also store how often a specific grail has been minted for
     * efficiency.
     */
    struct GrailConfig {
        GrailType grailType;
        uint16 numMinted;
        uint16 mintingCap;
        uint16 numVariants;
        uint16 genesisVariant;
    }

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The current Grails season.
     */
    uint256 public constant SEASON = 3;

    /**
     * @notice The number of different Grails in this season.
     */
    uint8 internal constant _NUM_GRAILS = 20;

    /**
     * @notice The price of purchasing a Grail by burning a mint pass.
     */
    uint256 internal constant _PRICE = 0.05 ether;

    /**
     * @notice The address to the mint pass contract.
     */
    Grails3MintPass internal immutable _mintPass;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The current stage of the contract.
     * @dev Some methods are only accessible for some stages. See also the
     * `Steering` section for more information.
     */
    Stage public stage;

    /**
     * @notice The Grail id and edition of a given token.
     */
    mapping(uint256 => Grail) internal _grailByTokenId;

    /**
     * @notice Stores the configuration of all grails.
     */
    GrailConfig[_NUM_GRAILS] internal _grailConfigs;

    /**
     * @notice The variant shufflers for limited series grails.
     * @dev Even though we do not have a shuffler for all grails, this array has
     * full length for simplicity. The unneeded shufflers will remain
     * uninitialised and therefore not add gas cost.
     */
    NextShuffler.State[_NUM_GRAILS] internal _shufflers;

    /**
     * @notice Implements ERC2981 royalties for grails.
     */
    IGrailsRoyaltyRouter public royaltyRouter;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    /**
     * @notice Constructor helper to configure a given grail as limited edition
     * with given parameters.
     * @dev Uses the standard minting cap for limited editions.
     */
    function _setupLimitedEdition(uint8 grailId) internal {
        _setupLimitedEdition(grailId, 50);
    }

    /**
     * @notice Constructor helper to configure a given grail as limited edition
     * with given parameters.
     */
    function _setupLimitedEdition(uint8 grailId, uint16 mintingCap) internal {
        _grailConfigs[grailId] = GrailConfig({
            grailType: GrailType.LimitedEdition,
            numMinted: 0,
            mintingCap: mintingCap,
            numVariants: 0,
            genesisVariant: 0
        });
    }

    /**
     * @notice Constructor helper to configure a given grail as limited series
     * with given parameters.
     * @dev Uses the standard minting cap for limited series.
     */
    function _setupLimitedSeries(
        uint8 grailId,
        uint16 numVariants,
        uint16 genesisVariant
    ) internal {
        _setupLimitedSeries(grailId, 150, numVariants, genesisVariant);
    }

    /**
     * @notice Constructor helper to configure a given grail as limited series
     * with given parameters.
     */
    function _setupLimitedSeries(
        uint8 grailId,
        uint16 mintingCap,
        uint16 numVariants,
        uint16 genesisVariant
    ) internal {
        assert(genesisVariant < numVariants);

        _grailConfigs[grailId] = GrailConfig({
            grailType: GrailType.LimitedSeries,
            numMinted: 0,
            mintingCap: mintingCap,
            numVariants: numVariants,
            genesisVariant: genesisVariant
        });
        _shufflers[grailId].init(numVariants);
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        Grails3MintPass mintPass_,
        IGrailsRoyaltyRouter royaltyRouter_
    )
        ERC721ACommon(name_, symbol_, payable(address(0xdeadface)), 0)
        BaseTokenURI(baseTokenURI_)
    {
        _mintPass = mintPass_;
        royaltyRouter = royaltyRouter_;

        _setupLimitedSeries(0, 150, 115);
        _setupLimitedEdition(1);
        _setupLimitedEdition(2);
        _setupLimitedEdition(3);
        _setupLimitedEdition(4);
        _setupLimitedEdition(5);
        _setupLimitedSeries(6, 150, 129);
        _setupLimitedEdition(7);
        _setupLimitedSeries(8, 8, 2);
        _setupLimitedEdition(9);
        _setupLimitedSeries(10, 12, 6);
        _setupLimitedEdition(11);
        _setupLimitedSeries(12, 150, 39);
        _setupLimitedEdition(13);
        _setupLimitedEdition(14);
        _setupLimitedEdition(15);
        _setupLimitedEdition(16);
        _setupLimitedSeries(17, 150, 14);
        _setupLimitedEdition(18);
        _setupLimitedEdition(19);
    }

    // =========================================================================
    //                           Minting
    // =========================================================================

    /**
     * @notice Mints the treasury reseverve.
     * This includes:
     * - 20 x Genesis tokens for artists
     * - 20 tokens for the treasury
     *     = 40 tokens
     * @dev Can only be called once.
     */
    function mintReserve(address to) external onlyOwner onlyOnce {
        uint8[] memory grailIds = new uint8[]( 2 * _NUM_GRAILS);
        for (uint8 i = 0; i < 2 * _NUM_GRAILS; ++i) {
            grailIds[i] = i % _NUM_GRAILS;
        }
        _doMints(to, grailIds);
    }

    /**
     * @notice Mints the artist allocation to a given address (treasury).
     * This includes one freely chosen token per artist (20).
     * @dev We perform the mints on behalf of the artists to obfruscate their
     * identity before the reveal.
     * @dev Can only be called once.
     */
    function mintArtistChoices(address to, uint8[] calldata choices)
        external
        onlyOwner
        onlyOnce
    {
        if (choices.length != _NUM_GRAILS) {
            revert IncorrectNumberOfGrails();
        }
        _doMints(to, choices);
    }

    // =========================================================================
    //                           Processing mints
    // =========================================================================

    /**
     * @notice Processes the mint of a given list of grailIds.
     */
    function _doMints(address to, uint8[] memory grailIds) internal {
        uint256 nextTokenId = totalSupply();
        uint256 len = grailIds.length;
        for (uint256 idx = 0; idx < len; ++idx) {
            _processMint(to, nextTokenId++, grailIds[idx]);
        }

        // Using unsafe mints here. The sender has already proven that it can
        // safely receive and handle ERC721 token (either because they already
        // hold mint passes or because the addresses are supplied by us).
        _mint(to, grailIds.length);
    }

    /**
     * @notice Processes the mint of a single grail.
     * @dev Reverts if the grailId is invalid.
     * @dev Reverts if the minting cap of the given grail is exhausted.
     */
    function _processMint(address to, uint256 tokenId, uint8 grailId)
        internal
    {
        if (grailId >= _NUM_GRAILS) {
            revert InvalidGrailId();
        }

        if (!_hasMintsRemaining(grailId)) {
            revert GrailMintingLimitReached(grailId);
        }

        if (_grailConfigs[grailId].grailType == GrailType.LimitedEdition) {
            _processLimitedEditionMint(tokenId, grailId);
        } else {
            _processLimitedSeriesMint(tokenId, grailId);
        }

        emit GrailMinted(to, grailId);
    }

    /**
     * @notice Processes the mint of a limited edition grail.
     */
    function _processLimitedEditionMint(uint256 tokenId, uint8 grailId)
        internal
    {
        _grailByTokenId[tokenId] = Grail({
            id: grailId,
            edition: _grailConfigs[grailId].numMinted++,
            variant: 0
        });
    }

    /**
     * @notice Processes the mint of a limited series grail.
     */
    function _processLimitedSeriesMint(uint256 tokenId, uint8 grailId)
        internal
    {
        GrailConfig memory cfg = _grailConfigs[grailId];
        NextShuffler.State storage shuffler = _shufflers[grailId];

        uint256 rand;
        if (cfg.numMinted == 0) {
            // The first mint of each series has to be the genesis variant.
            rand = cfg.genesisVariant;
        } else {
            rand = uint256(
                keccak256(abi.encodePacked(tokenId, block.difficulty))
            ) % (cfg.numVariants - (cfg.numMinted % cfg.numVariants));
        }

        _grailByTokenId[tokenId] = Grail({
            id: grailId,
            edition: _grailConfigs[grailId].numMinted++,
            variant: uint16(shuffler.next(rand))
        });

        // After all variants have been seen, we start the shuffler again.
        if (shuffler.finished()) {
            shuffler.restart();
        }
    }

    // =========================================================================
    //                           Redeeming mint passes
    // =========================================================================

    /**
     * @notice Redeems a given list of mint passes for a list of Grails.
     * @dev The Grail III tokens will be minted to the caller address.
     * @dev Reverts if the caller is not allowed to redeem passes.
     * @dev Can only be called if the contract is set to the open state.
     * @dev Passing control to our own contracts is effectively not an
     * interaction, so we are safe to go without reentrancy protection.
     */
    function redeemPasses(uint256[] calldata passIds, uint8[] memory grailIds)
        public
        payable
        onlyDuring(Stage.Open)
    {
        if (passIds.length != grailIds.length) {
            revert ParameterLengthMismatch();
        }

        _processPayment(grailIds.length);
        _burnPasses(passIds);
        _doMints(msg.sender, grailIds);
    }

    /**
     * @notice Redeems a list of mint passes for random grails.
     * @dev The Grail III tokens will be minted to the caller address.
     * @dev Reverts if the caller is not allowed to redeem passes.
     * @dev Can only be called if the contract is set to the open state.
     * @dev Passing control to our own contracts is effectively not an
     * interaction, so we are safe to go without reentrancy protection.
     */
    function feelingLucky(uint256[] calldata passIds)
        external
        payable
        onlyDuring(Stage.Open)
    {
        _processPayment(passIds.length);
        _burnPasses(passIds);

        PRNG.Source src = PRNG.newSource(
            keccak256(abi.encodePacked(totalSupply(), block.difficulty))
        );

        uint8[] memory grailIds = new uint8[](1);
        uint256 i;
        while (i < passIds.length) {
            uint8 grailId = uint8(src.readLessThan(_NUM_GRAILS));
            if (!_hasMintsRemaining(grailId)) {
                continue;
            }

            grailIds[0] = grailId;
            _doMints(msg.sender, grailIds);
            ++i;
        }
    }

    /**
     * @notice Checks if the payment is sufficient and forwards it to the
     * royalty router.
     * @dev Reverts otherwise.
     */
    function _processPayment(uint256 numMints) internal {
        if (msg.value != _PRICE * numMints) {
            revert InvalidFunds(_PRICE * numMints);
        }
        payable(address(royaltyRouter)).sendValue(msg.value);
    }

    /**
     * @notice Burns a list of mint passes.
     * @dev Reverts if the caller is not allowed to redeem passes.
     */
    function _burnPasses(uint256[] calldata passIds) internal {
        uint256 num = passIds.length;
        for (uint256 idx = 0; idx < num; ++idx) {
            _requirePassApproval(passIds[idx], msg.sender);
            _mintPass.redeem(passIds[idx]);
        }
    }

    // =========================================================================
    //                           Metadata
    // =========================================================================

    /**
     * @notice Returns the Grail id + edition for a given token.
     */
    function grailByTokenId(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (Grail memory)
    {
        return _grailByTokenId[tokenId];
    }

    /**
     * @notice Returns how often a given grail was minted.
     */
    function numMintedByGraildId(uint8 grailId) public view returns (uint16) {
        return _grailConfigs[grailId].numMinted;
    }

    /**
     * @notice Returns all tokens of a given grail.
     * @dev Attention: requires a lot of gas. This is intended to only be used
     * in read-only calls.
     */
    function tokenIdsByGrailId(uint8 grailId)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = new uint[](numMintedByGraildId(grailId));

        uint256 cursor;
        uint256 supply = totalSupply();
        for (uint256 tokenId; tokenId < supply; ++tokenId) {
            if (_grailByTokenId[tokenId].id == grailId) {
                tokenIds[cursor++] = tokenId;
            }
        }

        return tokenIds;
    }

    /**
     * @notice Triggers a collection wide metadata refresh following EIP-4906.
     */
    function refreshMetadata() external onlyOwner {
        emit BatchMetadataUpdate(0, totalSupply());
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Advances the stage of the contract.
     * @dev Can only be advanced after the treasury reserve has been minted to
     * ensure the genesis tokens are minted.
     */
    function setStage(Stage stage_) external onlyOwner {
        stage = stage_;
    }

    /**
     * @notice Ensures that the contract is in a given stage.
     */
    modifier onlyDuring(Stage stage_) {
        if (stage_ != stage) {
            revert DisallowedByCurrentStage();
        }
        _;
    }

    // =========================================================================
    //                           Secondary Royalties
    // =========================================================================

    /**
     * @notice Computes the creator royalty for a secondary token sale.
     * @dev The implementation is delegated to our royalty router contract.
     */
    function royaltyInfo(uint256 tokenId, uint256 price)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        return royaltyRouter.royaltyInfo(
            SEASON, _grailByTokenId[tokenId].id, tokenId, price
        );
    }

    /**
     * @notice Changes the royalty router address.
     */
    function setRoyaltyRouter(IGrailsRoyaltyRouter router) external onlyOwner {
        if (!router.supportsInterface(type(IGrailsRoyaltyRouter).interfaceId)) {
            revert InsufficientInterface();
        }
        royaltyRouter = router;
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @notice Checks if a given mint pass can be spent by the caller.
     * @dev Reverts if not.
     */
    function _requirePassApproval(uint256 passId, address operator)
        internal
        view
    {
        address passOwner = _mintPass.ownerOf(passId);
        if (
            passOwner == operator || _mintPass.getApproved(passId) == operator
                || _mintPass.isApprovedForAll(passOwner, operator)
        ) {
            return;
        }
        revert CallerNotAllowedToRedeemPass();
    }

    /**
     * @dev Inheritance resolution.
     */
    function _baseURI()
        internal
        view
        virtual
        override(ERC721A, BaseTokenURI)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    function _hasMintsRemaining(uint8 grailId) internal view returns (bool) {
        GrailConfig storage cfg = _grailConfigs[grailId];
        if (cfg.mintingCap == 0) {
            return true;
        }
        return cfg.numMinted < cfg.mintingCap;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ACommon, ERC4906)
        returns (bool)
    {
        return ERC721ACommon.supportsInterface(interfaceId)
            || ERC4906.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}