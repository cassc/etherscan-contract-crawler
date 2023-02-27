// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*

███╗   ███╗███████╗████████╗ █████╗ ██╗      █████╗ ██████╗ ███████╗██╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝██║
██╔████╔██║█████╗     ██║   ███████║██║     ███████║██████╔╝█████╗  ██║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██╔══██║██╔══██╗██╔══╝  ██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝


Deployed by Metalabel with 💖 as a permanent application on the Ethereum blockchain.

Metalabel is a growing universe of tools, knowledge, and resources for
metalabels and cultural collectives.

Our purpose is to establish the metalabel as key infrastructure for creative
collectives and to inspire a new culture of creative collaboration and mutual
support.

OUR SQUAD

Anna Bulbrook (Curator)
Austin Robey (Community)
Brandon Valosek (Engineer)
Ilya Yudanov (Designer)
Lauren Dorman (Engineer)
Rob Kalin (Board)
Yancey Strickler (Director)

https://metalabel.xyz

*/

import {Owned} from "@metalabel/solmate/src/auth/Owned.sol";
import {SSTORE2} from "@metalabel/solmate/src/utils/SSTORE2.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ICollection} from "../interfaces/ICollection.sol";
import {IEngine, SequenceData} from "../interfaces/IEngine.sol";
import {INodeRegistry} from "../interfaces/INodeRegistry.sol";

/// @notice Data stored engine-side for each drop.
/// - Royalty percentage is stored as basis points, eg 5% = 500
/// - If maxRecordPerTransaction is 0, there is not limit
/// - Protocol fee is written to drop data at configure-time to lock in protocol
///   fee and avoid an additional storage read at mint-time
struct DropData {
    uint96 price;
    uint16 royaltyBps;
    bool allowContractMints;
    bool randomizeMetadataVariants;
    uint8 maxRecordsPerTransaction;
    address revenueRecipient;
    uint16 primarySaleFeeBps;
    uint96 priceDecayPerDay;
    uint64 decayStopTimestamp;
    // 59 bytes total / 5 remaining for a two-word slot
}

/// @notice A single attribute of an NFT's metadata
struct NFTMetadataAttribute {
    string trait_type;
    string value;
}

/// @notice Metadata stored for a single record variant
/// @dev Storage is written via SSTORE2
struct NFTMetadata {
    string name;
    string description;
    string image;
    string external_url;
    string metalabel_record_variant_name;
    string metalabel_release_metadata_uri;
    uint16[] metalabel_record_contents;
    NFTMetadataAttribute[] attributes;
}

/// @notice Metalabel engine that implements a multi-NFT drop.
/// - All metadata is stored onchain via SSTORE2.
/// - Price can decay over time or be constant throughout the drop.
/// - Metadata variants can be p-randomized or fixed.
/// - Enabling or disabling smart contract mints is set per-sequence.
/// - Multiple records can be minted in a single trx, configurable per-sequence.
/// - The owner of this contract can set a primary sale fee that is taken from
///   all primary sales revenue and retained by this drop engine.
contract DropEngineV2 is IEngine, Owned {
    // ---
    // Errors
    // ---

    /// @notice Invalid msg.value on purchase
    error IncorrectPaymentAmount();

    /// @notice If price or recipient is zero, they both have to be zero
    error InvalidPriceOrRecipient();

    /// @notice An invalid value was used for the royalty bps.
    error InvalidRoyaltyBps();

    /// @notice An invalid value was used for the primary sale fee.
    error InvalidPrimarySaleFee();

    /// @notice If smart contract mints are not allowed, msg.sender must be an
    /// EOA
    error MinterMustBeEOA();

    /// @notice If minting more than the max allowed per transaction
    error InvalidMintAmount();

    /// @notice An invalid price decay stop time or per day decay was used.
    error InvalidPriceDecayConfig();

    /// @notice Unable to forward ETH to the revenue recipient or unable to
    /// withdraw funds
    error CouldNotTransferEth();

    // ---
    // Events
    // ---

    /// @notice A new drop was created.
    /// @dev The collection already emits a SequenceCreated event, we're
    /// emitting the additional engine-specific data here.
    event DropCreated(address collection, uint16 sequenceId, DropData dropData);

    /// @notice The primary sale for this drop engine was set
    event PrimarySaleFeeSet(uint16 primarySaleFeeBps);

    // ---
    // Storage
    // ---

    /// @notice Drop data for a given collection + sequence ID.
    mapping(address => mapping(uint16 => DropData)) public drops;

    /// @notice The SSTORE2 contract storage address for a given sequence's list
    /// of metadata variants
    mapping(address => mapping(uint16 => address))
        public metadataStoragePointers;

    /// @notice A primary sales fee that is paid at mint time. Can be adjusted
    /// by contract owner. Fee is written into the drop's DropData structure, so
    /// fee at configure-time is locked. Fees are accumulated in the contract
    /// and can be withdrawn by the contract owner
    uint16 public primarySaleFeeBps;

    /// @notice A reference to the core protocol's node registry.
    /// @dev While this is not directly used by the engine, it is surfaced in
    /// the onchain generated JSON metadata for records as a way of creating a
    /// concrete link back to the cataloging protocol.
    INodeRegistry public immutable nodeRegistry;

    // ---
    // Constructor
    // ---

    constructor(address _contractOwner, INodeRegistry _nodeRegistry)
        Owned(_contractOwner)
    {
        nodeRegistry = _nodeRegistry;
    }

    // ---
    // Admin functionality
    // ---

    /// @notice Set the primary sale fee for all drops configured on this
    /// engine. Only callable by owner
    function setPrimarySaleFeeBps(uint16 fee) external onlyOwner {
        if (fee > 10000) revert InvalidPrimarySaleFee();
        primarySaleFeeBps = fee;
        emit PrimarySaleFeeSet(fee);
    }

    // ---
    // Permissionless functions
    // ---

    /// @notice Transfer ETH from the contract that has accumulated from fees to
    /// the owner's account. Can be called by any address.
    function transferFeesToOwner() external {
        (bool success, ) = owner.call{value: address(this).balance}("");
        if (!success) revert CouldNotTransferEth();
    }

    // ---
    // Mint functionality
    // ---

    /// @notice Mint records. Returns the first token ID minted
    function mint(
        ICollection collection,
        uint16 sequenceId,
        uint8 count
    ) external payable returns (uint256 tokenId) {
        DropData storage drop = drops[address(collection)][sequenceId];

        // block SC mints if flagged
        if (!drop.allowContractMints && msg.sender != tx.origin) {
            revert MinterMustBeEOA();
        }

        // Ensure not minting too many
        if (
            drop.maxRecordsPerTransaction > 0 &&
            count > drop.maxRecordsPerTransaction
        ) {
            revert InvalidMintAmount();
        }

        // Resolve current unit price (which may change over time if there's a
        // price decay configuration) and total order price
        uint256 unitPrice = currentPrice(collection, sequenceId);
        uint256 orderPrice = unitPrice * count;

        // Ensure correct payment was sent with the transaction. Checking less
        // than to allow sender to overpay (likely happens for all decaying
        // prices). We refund the difference below.
        if (msg.value < orderPrice) {
            revert IncorrectPaymentAmount();
        }

        for (uint256 i = 0; i < count; i++) {
            // If collection is a malicious contract, that does not impact any
            // state in the engine.  If it's a valid protocol-deployed
            // collection, then it will work as expected.
            //
            // Collection enforces max mint supply and mint window, so we're not
            // checking that here
            uint256 id = collection.mintRecord(msg.sender, sequenceId);

            // return the first minted token ID, caller can infer subsequent
            // sequential IDs
            tokenId = tokenId != 0 ? tokenId : id;
        }

        // Amount to forward to the revenue recipient is the total order price
        // minus the locked-in primary sale fee that was recorded at
        // configure-time.  The remaining ETH (after refund) will stay in this
        // contract, withdrawable by the owner at a later date via
        // transferFeesToOwner
        uint256 amountToForward = orderPrice -
            ((orderPrice * drop.primarySaleFeeBps) / 10000);

        // Amount to refund message sender is any difference in order price and
        // msg.value. This happens if the caller overpays, which will generally
        // always happen on decaying price mints
        uint256 amountToRefund = msg.value > orderPrice
            ? msg.value - orderPrice
            : 0;

        // Refund caller
        if (amountToRefund > 0) {
            (bool success, ) = msg.sender.call{value: amountToRefund}("");
            if (!success) revert CouldNotTransferEth();
        }

        // Forward ETH to the revenue recipient
        if (amountToForward > 0) {
            (bool success, ) = drop.revenueRecipient.call{
                value: amountToForward
            }("");
            if (!success) revert CouldNotTransferEth();
        }
    }

    /// @notice Get the current price of a record in a given sequence. This will
    /// return a price even if the sequence is not currently mintable (i.e. the
    /// mint window hasn't started yet or the minting window has closed).
    function currentPrice(ICollection collection, uint16 sequenceId)
        public
        view
        returns (uint256 unitPrice)
    {
        DropData storage drop = drops[address(collection)][sequenceId];

        // Compute unit price based on decay and timestamp.
        // First compute how many seconds until the decay cutoff time, after
        // which price will remain constant. Then compute the marginal increase
        // in unit price by multiplying the base price by
        //
        //   (decay per day * seconds until decay stop) / 1 day
        //

        uint64 secondsBeforeDecayStop = block.timestamp <
            drop.decayStopTimestamp
            ? drop.decayStopTimestamp - uint64(block.timestamp)
            : 0;
        uint256 inflateUnitPriceBy = (uint256(drop.priceDecayPerDay) *
            secondsBeforeDecayStop) / 1 days;
        unitPrice = drop.price + inflateUnitPriceBy;
    }

    // ---
    // IEngine setup
    // ---

    /// @inheritdoc IEngine
    /// @dev There is no access control on this function, we infer the
    /// collection from msg.sender, and use that to key all stored data. If
    /// somebody calls this function with bogus info (instead of it getting
    /// called via the collection), it just wastes storage but does not impact
    /// contract functionality
    function configureSequence(
        uint16 sequenceId,
        SequenceData calldata sequenceData,
        bytes calldata engineData
    ) external override {
        (DropData memory dropData, NFTMetadata[] memory metadatas) = abi.decode(
            engineData,
            (DropData, NFTMetadata[])
        );

        // This drop is a "free drop" if and only if the price is zero and decay
        // per day is zero
        bool isFreeDrop = dropData.price == 0 && dropData.priceDecayPerDay == 0;

        // Ensure that if this is a free drop, there's no revenue recipient, and
        // vice versa
        if ((isFreeDrop) != (dropData.revenueRecipient == address(0))) {
            revert InvalidPriceOrRecipient();
        }

        // Don't allow setting a decay stop time in the past (or before the mint
        // window opens) unless it's zero.
        if (
            dropData.decayStopTimestamp != 0 &&
            (dropData.decayStopTimestamp < block.timestamp ||
                dropData.decayStopTimestamp <
                sequenceData.sealedBeforeTimestamp)
        ) {
            revert InvalidPriceDecayConfig();
        }

        // Don't allow setting a decay stop time after the mint window closes
        if (
            sequenceData.sealedAfterTimestamp > 0 && // sealed = 0 -> no end
            dropData.decayStopTimestamp > sequenceData.sealedAfterTimestamp
        ) {
            revert InvalidPriceDecayConfig();
        }

        // Ensure that if decay stop time is set, decay per day is set, and vice
        // versa
        if (
            (dropData.decayStopTimestamp == 0) !=
            (dropData.priceDecayPerDay == 0)
        ) {
            revert InvalidPriceDecayConfig();
        }

        // Ensure royaltyBps is in range
        if (dropData.royaltyBps > 10000) revert InvalidRoyaltyBps();

        // To ensure that creators know the protocol fee they are effectively
        // agreeing to during sequence creation time, we require that they set
        // the primary sale fee correctly here. This also ensures the drop
        // engine owner cannot frontrun a fee change
        if (dropData.primarySaleFeeBps != primarySaleFeeBps) {
            revert InvalidPrimarySaleFee();
        }

        // write metadata blob to chain
        metadataStoragePointers[msg.sender][sequenceId] = SSTORE2.write(
            abi.encode(metadatas)
        );

        // Write engine data (passed through from the collection when the
        // collection admin calls `configureSequence`) to a struct in the engine
        // with all the needed info.
        drops[msg.sender][sequenceId] = dropData;
        emit DropCreated(msg.sender, sequenceId, dropData);
    }

    // ---
    // IEngine views
    // ---

    /// @inheritdoc IEngine
    /// @dev Token URI is constructed programmatically from stored metadata by
    /// creating the JSON string and base64ing it
    function getTokenURI(address collection, uint256 tokenId)
        external
        view
        override
        returns (string memory tokenURI)
    {
        uint16 sequenceId = ICollection(collection).tokenSequenceId(tokenId);
        uint80 editionNumber = ICollection(collection).tokenMintData(tokenId);
        SequenceData memory sequenceData = ICollection(collection)
            .getSequenceData(sequenceId);

        NFTMetadata memory metadata = getStoredMetadataVariant(
            collection,
            tokenId
        );

        // Construct edition string as either "1" or "1/1000" depending on if
        // this was an open edition
        string memory sEdition = sequenceData.maxSupply == 0
            ? Strings.toString(editionNumber)
            : string.concat(
                Strings.toString(editionNumber),
                "/",
                Strings.toString(sequenceData.maxSupply)
            );

        // Edition number and variant name are always included
        string memory attributesInnerJson = string.concat(
            '{"trait_type": "Record Edition", "value": "',
            sEdition,
            '"}, {"trait_type": "Record Variant", "value": "',
            metadata.metalabel_record_variant_name,
            '"}',
            metadata.attributes.length > 0 ? ", " : ""
        );

        // Additional attributes from metadata blob
        for (uint256 i = 0; i < metadata.attributes.length; i++) {
            attributesInnerJson = string.concat(
                attributesInnerJson,
                i > 0 ? ", " : "",
                '{"trait_type": "',
                metadata.attributes[i].trait_type,
                '", "value": "',
                metadata.attributes[i].value,
                '"}'
            );
        }

        // create the contents array
        string memory contentsInnerJson = "[";
        for (
            uint256 i = 0;
            i < metadata.metalabel_record_contents.length;
            i++
        ) {
            contentsInnerJson = string.concat(
                contentsInnerJson,
                Strings.toString(metadata.metalabel_record_contents[i]),
                i == metadata.metalabel_record_contents.length - 1 ? "]" : ", "
            );
        }

        // Compose the final JSON payload. Split across multiple string.concat
        // calls due to stack limitations
        string memory json = string.concat(
            '{"name":"',
            metadata.name,
            " ",
            sEdition,
            '", "description":"',
            metadata.description,
            '", "image": "',
            metadata.image,
            '", "external_url": "',
            metadata.external_url,
            '", '
        );
        json = string.concat(
            json,
            '"metalabel": { "node_registry_address": "',
            Strings.toHexString(uint256(uint160(address(nodeRegistry))), 20),
            '", "record_variant_name": "',
            metadata.metalabel_record_variant_name,
            '", "release_metadata_uri": "',
            metadata.metalabel_release_metadata_uri,
            '", "record_contents": ',
            contentsInnerJson,
            '}, "attributes": [',
            attributesInnerJson,
            "]}"
        );

        // Prepend base64 prefix + encode JSON
        tokenURI = string.concat(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        );
    }

    /// @notice Get the onchain metadata variant for a specific record
    /// @dev This is a view function that reads from SSTORE2 storage and picks
    /// the random or sequential variant, the full onchain metadata is
    /// generated in tokenURI
    function getStoredMetadataVariant(address collection, uint256 tokenId)
        public
        view
        returns (NFTMetadata memory metadata)
    {
        uint16 sequenceId = ICollection(collection).tokenSequenceId(tokenId);
        uint80 editionNumber = ICollection(collection).tokenMintData(tokenId);

        // Load all metadata variants from SSTORE2 storage
        NFTMetadata[] memory metadatas = abi.decode(
            SSTORE2.read(metadataStoragePointers[collection][sequenceId]),
            (NFTMetadata[])
        );

        // Metadata variants are default sequential, but can be pseudo-random
        // if the randomizeMetadataVariants flag is set.
        // Using (edition - 1) for sequential since edition number starts at 1
        uint256 idx = (editionNumber - 1) % metadatas.length;
        if (drops[collection][sequenceId].randomizeMetadataVariants) {
            idx =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            collection,
                            sequenceId,
                            editionNumber,
                            tokenId
                        )
                    )
                ) %
                metadatas.length;
        }

        metadata = metadatas[idx];
    }

    /// @inheritdoc IEngine
    /// @dev Royalty bps and recipient is per-sequence.
    function getRoyaltyInfo(
        address collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address, uint256) {
        uint16 sequenceId = ICollection(collection).tokenSequenceId(tokenId);
        DropData storage drop = drops[collection][sequenceId];
        return (drop.revenueRecipient, (salePrice * drop.royaltyBps) / 10000);
    }
}