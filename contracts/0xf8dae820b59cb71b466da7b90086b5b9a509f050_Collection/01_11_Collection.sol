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

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ERC721} from "@metalabel/solmate/src/tokens/ERC721.sol";
import {SSTORE2} from "@metalabel/solmate/src/utils/SSTORE2.sol";
import {INodeRegistry} from "./interfaces/INodeRegistry.sol";
import {IEngine, SequenceData} from "./interfaces/IEngine.sol";
import {ICollection} from "./interfaces/ICollection.sol";
import {Resource, AccessControlData} from "./Resource.sol";

/// @notice Immutable data stored per-collection.
/// @dev This is stored via SSTORE2 to save gas.
struct ImmutableCollectionData {
    string name;
    string symbol;
    string contractURI;
}

/// @notice Collections are ERC721 contracts that contain records.
/// - Minting logic, tokenURI, and royalties are delegated to an external engine
///     contract
/// - Sequences are a mapping between an external engine contract and parameters
///     stored in the collection
/// - Multiple sequences can be configured for a single collection, records may
///     be rendered and minted in a variety of different ways
contract Collection is ERC721, Resource, ICollection, IERC2981 {
    // ---
    // Errors
    // ---

    /// @notice The init function was called more than once.
    error AlreadyInitialized();

    /// @notice A record mint attempt was made for a sequence that is currently
    /// sealed.
    error SequenceIsSealed();

    /// @notice A record mint attempt was made for a sequence that has no
    /// remaining supply.
    error SequenceSupplyExhausted();

    /// @notice An invalid sequence config was provided during configuration.
    error InvalidSequenceConfig();

    /// @notice msg.sender during a mint call did not match expected engine
    /// origin.
    error InvalidMintRequest();

    // ---
    // Events
    // ---

    /// @notice A new record was minted.
    /// @dev The underlying ERC721 implementation already emits a Transfer event
    /// on mint, this event announces the sequence the token is minted into and
    /// its immutable token data.
    event RecordCreated(
        uint256 indexed tokenId,
        uint16 indexed sequenceId,
        uint80 data
    );

    /// @notice A sequence has been set or updated.
    event SequenceConfigured(
        uint16 indexed sequenceId,
        SequenceData sequenceData,
        bytes engineData
    );

    /// @notice The owner address of this collection was updated.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // ---
    // Storage
    // ---

    /// @notice Total number of records minted in this collection.
    uint256 public totalSupply;

    /// @notice Total number of sequences configured in this collection.
    uint16 public sequenceCount;

    /// @notice Only for marketplace interop, can be set by owner of the control
    /// node.
    address public owner;

    /// @notice The SSTORE2 storage pointer for immutable collection data.
    /// @dev This data is exposed through name, symbol, and contractURI views
    address internal immutableStoragePointer;

    /// @notice Information about each sequence.
    mapping(uint16 => SequenceData) internal sequences;

    // ---
    // Constructor
    // ---

    /// @dev Constructor only called during deployment of the implementation,
    /// all storage should be set up in init function which is called atomically
    /// after clone deployment
    constructor() {
        // Write dummy data to the immutable storage pointer to prevent
        // initialization of the implementation contract.
        immutableStoragePointer = SSTORE2.write(
            abi.encode(
                ImmutableCollectionData({name: "", symbol: "", contractURI: ""})
            )
        );
    }

    // ---
    // Clone init
    // ---

    /// @notice Initialize contract state.
    /// @dev Should be called immediately after deploying the clone in the same
    /// transaction.
    function init(
        address _owner,
        AccessControlData calldata _accessControl,
        string calldata _metadata,
        ImmutableCollectionData calldata _data
    ) external {
        if (immutableStoragePointer != address(0)) revert AlreadyInitialized();
        immutableStoragePointer = SSTORE2.write(abi.encode(_data));

        // Set ERC721 market interop.
        owner = _owner;
        emit OwnershipTransferred(address(0), owner);

        // Assign access control data.
        accessControl = _accessControl;

        // This memberships collection is a resource that can be cataloged -
        // emit the initial metadata value
        emit Broadcast("metadata", _metadata);
    }

    // ---
    // Admin functionality
    // ---

    /// @notice Change the owner address of this collection.
    /// @dev This is only here for market interop, access control is handled via
    /// the control node.
    function setOwner(address _owner) external onlyAuthorized {
        address previousOwner = owner;
        owner = _owner;
        emit OwnershipTransferred(previousOwner, _owner);
    }

    /// @notice Create a new sequence configuration.
    /// @dev The _engineData bytes parameter is arbitrary data that is passed
    /// directly to the engine powering this new sequence.
    function configureSequence(
        SequenceData calldata _sequence,
        bytes calldata _engineData
    ) external onlyAuthorized {
        // The drop this sequence is associated with must be manageable by
        // msg.sender. This is in addition to the onlyAuthorized modifier which
        // asserts msg.sender can manage the control node of the whole
        // collection.
        // msg.sender is either a metalabel admin EOA, or a controller contract
        // that has been authorized to do drops on the drop node.
        if (
            !accessControl.nodeRegistry.isAuthorizedAddressForNode(
                _sequence.dropNodeId,
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }

        // If there is sealedAfter timestamp (i.e timebound sequence), ensure
        // that sealedBefore is strictly less than sealedAfter AND that
        // sealedAfter occurs strictly in the future. If sealedAfter is zero,
        // there is no time limit. We are allowing cases where sealedBefore
        // occurs in the past.
        if (
            _sequence.sealedAfterTimestamp > 0 &&
            (_sequence.sealedBeforeTimestamp >=
                _sequence.sealedAfterTimestamp ||
                _sequence.sealedAfterTimestamp <= block.timestamp)
        ) {
            revert InvalidSequenceConfig();
        }

        // Prevent having a minted count before the sequence starts. This
        // wouldn't break anything, but would cause the indexed "minted" amount
        // from actual mints to differ from the sequence data tracking total
        // supply, which is non-ideal and worth the small gas to check.
        //
        // We're not using a separate struct here for inputs that omits the
        // minted count field, being able to copy from calldata to storage is
        // nice.
        if (_sequence.minted != 0) {
            revert InvalidSequenceConfig();
        }

        // Write sequence data to storage
        uint16 sequenceId = ++sequenceCount;
        sequences[sequenceId] = _sequence;
        emit SequenceConfigured(sequenceId, _sequence, _engineData);

        // Invoke configureSequence on the engine to give it a chance to setup
        // and store any needed info. Doing this after event emitting so that
        // indexers see the sequence first before any engine-side events
        _sequence.engine.configureSequence(sequenceId, _sequence, _engineData);
    }

    // ---
    // Engine functionality
    // ---

    /// @inheritdoc ICollection
    function mintRecord(
        address to,
        uint16 sequenceId,
        uint80 tokenData
    ) external returns (uint256 tokenId) {
        SequenceData storage sequence = sequences[sequenceId];
        _validateSequence(sequence);

        // Mint the record.
        tokenId = ++totalSupply;
        ++sequence.minted;
        _mint(to, tokenId, sequenceId, tokenData);
        emit RecordCreated(tokenId, sequenceId, tokenData);
    }

    /// @inheritdoc ICollection
    function mintRecord(address to, uint16 sequenceId)
        external
        returns (uint256 tokenId)
    {
        SequenceData storage sequence = sequences[sequenceId];
        _validateSequence(sequence);

        // Mint the record.
        tokenId = ++totalSupply;
        uint64 editionNumber = ++sequence.minted;
        _mint(to, tokenId, sequenceId, editionNumber);
        emit RecordCreated(tokenId, sequenceId, editionNumber);
    }

    /// @dev Ensure a given sequence is valid to mint into by the current msg.sender
    function _validateSequence(SequenceData memory sequence) internal view {
        // Ensure that only the engine for this sequence can mint records. Mint
        // transactions termiante on the engine side - the engine then invokes
        // the mint functions on the Collection.
        if (sequence.engine != IEngine(msg.sender)) {
            revert InvalidMintRequest();
        }

        // Ensure that mint is not happening before or after allowed window.
        if (
            block.timestamp < sequence.sealedBeforeTimestamp ||
            (sequence.sealedAfterTimestamp > 0 && // sealed after = 0 => no end
                block.timestamp >= sequence.sealedAfterTimestamp)
        ) {
            revert SequenceIsSealed();
        }

        // Ensure we have remaining supply to mint
        if (sequence.maxSupply > 0 && sequence.minted >= sequence.maxSupply) {
            revert SequenceSupplyExhausted();
        }
    }

    // ---
    // ICollection views
    // ---

    /// @inheritdoc ICollection
    function getSequenceData(uint16 sequenceId)
        external
        view
        override
        returns (SequenceData memory sequence)
    {
        sequence = sequences[sequenceId];
    }

    // ---
    // ERC721 views
    // ---

    /// @notice The collection name.
    function name() public view virtual returns (string memory value) {
        value = _resolveImmutableStorage().name;
    }

    /// @notice The collection symbol.
    function symbol() public view virtual returns (string memory value) {
        value = _resolveImmutableStorage().symbol;
    }

    /// @inheritdoc ERC721
    /// @dev Resolve token URI from the engine powering the sequence.
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory uri)
    {
        IEngine engine = sequences[_tokenData[tokenId].sequenceId].engine;
        uri = engine.getTokenURI(address(this), tokenId);
    }

    /// @notice Get the contract URI.
    function contractURI() public view virtual returns (string memory value) {
        value = _resolveImmutableStorage().contractURI;
    }

    // ---
    // Misc views
    // ---

    /// @inheritdoc ICollection
    function tokenSequenceId(uint256 tokenId)
        external
        view
        returns (uint16 sequenceId)
    {
        sequenceId = _tokenData[tokenId].sequenceId;
    }

    /// @inheritdoc ICollection
    /// @dev Token mint data is either edition number or arbitrary custom data
    /// passed in the by the engine at mint-time.
    function tokenMintData(uint256 tokenId)
        external
        view
        returns (uint80 data)
    {
        data = _tokenData[tokenId].data;
    }

    // ---
    // ERC2981 functionality
    // ---

    /// @inheritdoc IERC2981
    /// @dev Resolve royalty info from the engine powering the sequence.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        IEngine engine = sequences[_tokenData[tokenId].sequenceId].engine;
        return engine.getRoyaltyInfo(address(this), tokenId, salePrice);
    }

    // ---
    // Introspection
    // ---

    /// @inheritdoc IERC165
    /// @dev ERC165 checks return true for: ERC165, ERC721, and ERC2981.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ---
    // Internal views
    // ---

    /// @dev Read name/symbol/contractURI strings via SSTORE2.
    function _resolveImmutableStorage()
        internal
        view
        returns (ImmutableCollectionData memory data)
    {
        data = abi.decode(
            SSTORE2.read(immutableStoragePointer),
            (ImmutableCollectionData)
        );
    }
}