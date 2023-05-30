// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EclipseAccess} from "../access/EclipseAccess.sol";
import {IEclipseMinter} from "../interface/IEclipseMinter.sol";

/**
 * Eclipse ERC721 contract factory
 */

struct CollectionParams {
    address artist;
    string name;
    string symbol;
    string script;
    uint8 collectionType;
    uint24 maxSupply;
    address contractAdmin;
    uint8 erc721Index;
    address[] minters;
    address paymentSplitter;
}
struct CollectionEvent {
    uint256 id;
    address contractAddress;
    uint8 collectionType;
    address artist;
    string name;
    string symbol;
    string script;
    uint24 maxSupply;
    address implementation;
    address paymentSplitter;
}
struct CollectionType {
    string name;
    uint256 prefix;
    uint256 lastId;
}

struct InitializerParams {
    uint256 id;
    address artist;
    string name;
    string symbol;
    uint24 maxSupply;
    address contractAdmin;
    address[] minters;
    address paymentSplitter;
}

contract EclipseCollectionFactory is EclipseAccess {
    mapping(uint8 => address) public erc721Implementations;
    mapping(uint8 => CollectionType) public collectionTypes;

    address public paymentSplitterImplementation;
    string public uri;

    event Created(CollectionEvent collection);

    constructor(string memory uri_) EclipseAccess() {
        uri = uri_;
        uint256 chain;
        assembly {
            chain := chainid()
        }
        collectionTypes[0] = CollectionType(
            "js",
            chain * 1_000_000_000 + 100_000_000,
            0
        );
    }

    /**
     * @dev Get next collection id
     */
    function _getNextCollectionId(
        uint8 collectionType
    ) internal returns (uint256) {
        CollectionType storage obj = collectionTypes[collectionType];
        require(obj.prefix != 0, "invalid collectionType");
        obj.lastId += 1;
        uint256 id = obj.prefix + obj.lastId;
        return id;
    }

    /**
     * @dev Create initializer for clone
     * Note The method signature is created on chain to prevent malicious initialization args
     */
    function _createInitializer(
        InitializerParams memory params
    ) internal view returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "initialize(string,string,string,uint256,uint24,address,address,address,address[],address)",
                params.name,
                params.symbol,
                uri,
                params.id,
                params.maxSupply,
                eclipseAdmin,
                params.contractAdmin,
                params.artist,
                params.minters,
                params.paymentSplitter
            );
    }

    /**
     * @dev Cone an implementation contract
     */
    function cloneCollectionContract(
        CollectionParams memory params
    ) external onlyAdmin returns (address, uint256) {
        address implementation = erc721Implementations[params.erc721Index];
        require(implementation != address(0), "invalid erc721Index");
        uint24 maxSupply = params.maxSupply;
        require(maxSupply <= 99_999, "maxSupply must not be greater 99.999");
        uint8 collectionType = params.collectionType;
        uint256 id = _getNextCollectionId(collectionType);
        address paymentSplitter = params.paymentSplitter;
        address artist = params.artist;
        address contractAdmin = params.contractAdmin;
        address[] memory minters = params.minters;
        string memory symbol = params.symbol;
        string memory name = params.name;
        string memory script = params.script;
        bytes memory initializer = _createInitializer(
            InitializerParams(
                id,
                artist,
                name,
                symbol,
                maxSupply,
                contractAdmin,
                minters,
                paymentSplitter
            )
        );
        address instance = Clones.cloneDeterministic(
            implementation,
            bytes32(block.number)
        );
        Address.functionCall(instance, initializer);
        emit Created(
            CollectionEvent(
                id,
                instance,
                collectionType,
                artist,
                name,
                symbol,
                script,
                maxSupply,
                implementation,
                paymentSplitter
            )
        );
        return (instance, id);
    }

    /**
     * @dev Add an ERC721 implementation contract and map by index
     */
    function addErc721Implementation(
        uint8 index,
        address implementation
    ) external onlyAdmin {
        erc721Implementations[index] = implementation;
    }

    /**
     * @dev Add a collectionType and map by index
     */
    function addCollectionType(
        uint8 index,
        string memory name,
        uint256 prefix,
        uint256 lastId
    ) external onlyAdmin {
        collectionTypes[index] = CollectionType(name, prefix, lastId);
    }

    /**
     * @dev Sets the base tokenURI for collections
     */
    function setUri(string memory uri_) external onlyAdmin {
        uri = uri_;
    }

    /**
     * @dev Predict contract address for new collection
     */
    function predictDeterministicAddress(
        uint8 erc721Index
    ) external view returns (address) {
        return
            Clones.predictDeterministicAddress(
                erc721Implementations[erc721Index],
                bytes32(block.number),
                address(this)
            );
    }
}