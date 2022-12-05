// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {Clone} from "clones-with-immutable-args/Clone.sol";
import {ERC721} from "@metalabel/solmate/src/tokens/ERC721.sol";
import {INodeRegistry} from "./interfaces/INodeRegistry.sol";
import {IEngine, SequenceData} from "./interfaces/IEngine.sol";
import {ICollection} from "./interfaces/ICollection.sol";
import {Resource} from "./Resource.sol";

/// @notice Collections are ERC721 contracts that contain records.
/// - Minting logic, tokenURI, and royalties are delegated to an external engine
///     contract
/// - Sequences are a mapping between an external engine contract and parameters
///     stored in the collection
/// - Multiple sequences can be configured for a single collection, records may
///     be rendered and minted in a variety of different ways
/// - This contract is deployed as an immutable cloned proxy by CollectionFactory
contract Collection is ERC721, Resource, Clone, ICollection, IERC2981 {
    // ---
    // Errors
    // ---

    /// @notice The init function was called more than once.
    error AlreadyInitialized();

    /// @notice A record mint attempt was made for a sequence that is currently sealed.
    error SequenceIsSealed();

    /// @notice A record mint attempt was made for a sequence that has no remaining supply.
    error SequenceSupplyExhausted();

    /// @notice An invalid sequence config was provided during configuration.
    error InvalidSequenceConfig();

    /// @notice msg.sender during a mint call did not match expected engine origin.
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

    /// @notice Information about each sequence.
    mapping(uint16 => SequenceData) public sequences;

    /// @notice Set true once a clone has been initialized.
    bool private initialized;

    // ---
    // Constructor
    // ---

    /// @dev Constructor only called during deployment of the implementation,
    /// all storage should be set up in init function which is called atomically
    /// after clone deployment
    constructor() ERC721("Collection", "COLLECTION") {
        initialized = true;
    }

    // ---
    // Clone init
    // ---

    /// @notice Initialize contract state.
    /// @dev Should be called immediately after deploying the clone in the same transaction.
    function init(
        string calldata _name,
        string calldata _symbol,
        address _owner,
        string calldata _contractURI
    ) external {
        if (initialized) revert AlreadyInitialized();
        initialized = true;

        // Set immutable collection data, not using clone-with-immutable args
        // here, variable length CWIA data is a bit more complex
        name = _name;
        symbol = _symbol;

        // Set ERC721 market interop.
        owner = _owner;
        emit OwnershipTransferred(address(0), owner);

        // The collection URI is stored and broadcast on metadata topic. Not
        // using broadcastAndStore method for this since msg.sender is not the
        // owner of the control node (its CollectionFactory at this point)
        messageStorage["metadata"] = _contractURI;
        emit Broadcast("metadata", _contractURI);

        // Control node and node registry reference are not part of init data,
        // they are set as part of the clone-with-immutable-args data and are
        // immutable.
    }

    // ---
    // Admin functionality
    // ---

    /// @notice Change the owner address of this collection.
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
        // The drop this sequence is associated with must be managaeable by
        // msg.sender.
        if (
            !nodeRegistry().isAuthorizedAddressForNode(
                _sequence.dropNodeId,
                msg.sender
            )
        ) {
            revert NotAuthorized();
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
        // Ensure that only the engine for this sequence can mint records.
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
    // IResource views
    // ---

    /// @inheritdoc Resource
    function nodeRegistry() public pure override returns (INodeRegistry nodes) {
        // The first of the immutable args written to code during clone deployment
        nodes = INodeRegistry(_getArgAddress(0));
    }

    /// @inheritdoc Resource
    function controlNode() public pure override returns (uint64 nodeId) {
        // Second of the immutable args written to code during clone deployment,
        // 20 byte offset since first immutable arg is an address
        nodeId = _getArgUint64(20);
    }

    // ---
    // ERC721 functionality
    // ---

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

    /// @notice Get the collection URI from resource storage.
    function contractURI() public view virtual returns (string memory uri) {
        uri = messageStorage["metadata"];
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
}