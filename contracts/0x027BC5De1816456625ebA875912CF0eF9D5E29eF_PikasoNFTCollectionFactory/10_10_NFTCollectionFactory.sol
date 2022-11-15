// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/internal/INFTCollectionInitializer.sol";
import "./libraries/AddressLibrary.sol";

/**
 * @title A factory to create NFT collections.
 * @notice Call this factory to create NFT collections.
 * @dev This creates and initializes an ERC-1167 minimal proxy pointing to an NFT collection contract implementation.
 * @author interakt
 */
contract PikasoNFTCollectionFactory is Initializable, OwnableUpgradeable {
    //
    using AddressUpgradeable for address;
    using Clones for address;
    using Strings for uint32;

    /**
     * @notice The address of the implementation all new NFTCollections will leverage.
     * @dev When this is changed, `versionNFTCollection` is incremented.
     * @return The implementation address for NFTCollection.
     */
    address public implementationNFTCollection;

    /**
     * @notice Emitted when the implementation of NFTCollection used by new collections is updated.
     * @param implementation The new implementation contract address.
     */
    event ImplementationNFTCollectionUpdated(address indexed implementation);

    /**
     * @notice Emitted when the implementation of NFTDropCollection used by new collections is updated.
     * @param implementationNFTDropCollection The new implementation contract address.
     * @param version The version of the new implementation, auto-incremented.
     */

    /**
     * @notice Emitted when a new NFTCollection is created from this factory.
     * @param collection The address of the new NFT collection contract.
     * @param creator The address of the creator which owns the new collection.
     * @param name The name of the collection contract created.
     * @param symbol The symbol of the collection contract created.
     * @param nonce The nonce used by the creator when creating the collection,
     * used to define the address of the collection.
     */
    event NFTCollectionCreated(
        address indexed collection,
        address indexed creator,
        string name,
        string symbol,
        uint256 nonce
    );

    modifier onlyContract(address _implementation) {
        require(
            _implementation.isContract(),
            "NFTCollectionFactory: Implementation is not a contract"
        );
        _;
    }

    /**
     * @notice Initializer called after contract creation.
     * @dev This is used so that this factory will resume versions from where our original factory had left off.
     */
    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @notice Allows Foundation to change the NFTCollection implementation used for future collections.
     * This call will auto-increment the version.
     * Existing collections are not impacted.
     * @param _implementation The new NFTCollection collection implementation address.
     */
    function adminUpdateNFTCollectionImplementation(address _implementation)
        external
        onlyOwner
        onlyContract(_implementation)
    {
        implementationNFTCollection = _implementation;
        emit ImplementationNFTCollectionUpdated(_implementation);
    }

    /**
     * @notice Create a new collection contract.
     * @dev The nonce must be unique for the msg.sender + implementation version, otherwise this call will revert.
     * @param name The collection's `name`.
     * @param symbol The collection's `symbol`.
     * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
     * @return collection The address of the newly created collection contract.
     */
    function createNFTCollection(
        string calldata name,
        string calldata symbol,
        uint96 nonce
    ) external returns (address collection) {
        require(
            bytes(symbol).length != 0,
            "NFTCollectionFactory: Symbol is required"
        );

        // This reverts if the NFT was previously created using this implementation version + msg.sender + nonce
        collection = implementationNFTCollection.cloneDeterministic(
            _getSalt(msg.sender, nonce)
        );

        INFTCollectionInitializer(collection).initialize(
            name,
            symbol,
            msg.sender
        );

        emit NFTCollectionCreated(collection, msg.sender, name, symbol, nonce);
    }

    /**
     * @notice Returns the address of a collection given the current implementation version, creator, and nonce.
     * This will return the same address whether the collection has already been created or not.
     * @param creator The creator of the collection.
     * @param nonce An arbitrary value used to allow a creator to mint multiple collections with a counterfactual address.
     * @return collection The address of the collection contract that would be created by this nonce.
     */
    function predictNFTCollectionAddress(address creator, uint96 nonce)
        external
        view
        returns (address collection)
    {
        collection = implementationNFTCollection.predictDeterministicAddress(
            _getSalt(creator, nonce)
        );
    }

    /**
     * @dev Salt is address + nonce packed.
     */
    function _getSalt(address creator, uint96 nonce)
        private
        pure
        returns (bytes32)
    {
        return bytes32((uint256(uint160(creator)) << 96) | uint256(nonce));
    }
}