//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../erc721/ERC721Editions.sol";
import "../erc721/ERC721SingleEdition.sol";
import "../erc721/ERC721General.sol";
import "../metadata/interfaces/IEditionsMetadataRenderer.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title CollectionFactory
 * @author [email protected], [email protected]
 * @dev Factory Contract to setup collections
 */
contract CollectionFactory {
    /**
     * @dev MintManager for controlling all mint functionality
     */
    address public immutable mintManagerAddress;

    /**
     * @dev EditionsMetadataRenderer for handling Editions Metadata
     */
    address public immutable editionsMetadataRendererAddress;

    /**
     * @dev ERC721Editions implementation
     */
    address public immutable erc721EditionsImplementation;

    /**
     * @dev ERC721SingleEdition implementation
     */
    address public immutable erc721SingleEditionImplementation;

    /**
     * @dev ERC721General implementation
     */
    address public immutable erc721GeneralImplementation;

    /**
     * @dev Trusted forwarder of meta-transactions
     */
    address public immutable trustedForwarder;

    /**
     * @dev Initialize factory
     * @param _trustedForwarder Trusted meta-tx executor for system
     * @param _mintManagerAddress MintManager for controlling all mint functionality
     * @param _editionsMetadataRendererAddress EditionsMetadataRenderer for handling Editions Metadata
     * @param _erc721EditionsImplementation ERC721Editions implementation
     * @param _erc721SingleEditionImplementation ERC721SingleEdition implementation
     * @param _erc721GeneralImplementation ERC721General implementation
     */
    constructor(
        address _trustedForwarder,
        address _mintManagerAddress,
        address _editionsMetadataRendererAddress,
        address _erc721EditionsImplementation,
        address _erc721SingleEditionImplementation,
        address _erc721GeneralImplementation
    ) {
        trustedForwarder = _trustedForwarder;

        mintManagerAddress = _mintManagerAddress;

        editionsMetadataRendererAddress = _editionsMetadataRendererAddress;

        erc721EditionsImplementation = _erc721EditionsImplementation;
        erc721SingleEditionImplementation = _erc721SingleEditionImplementation;
        erc721GeneralImplementation = _erc721GeneralImplementation;
    }

    /**
     * @dev Initialize ERC721Edition collection, deployed via Create2
     * @param _creator Creator/owner of contract
     * @param _defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param salt Salt used to uniquely deploy collection (via Create2)
     */
    function setupERC721EditionCollection(
        address _creator,
        IRoyaltyManager.Royalty memory _defaultRoyalty,
        address _defaultTokenManager,
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        bytes32 salt // generate off-chain
    ) external returns (address) {
        address clone = Clones.cloneDeterministic(erc721EditionsImplementation, salt);
        ERC721Editions(clone).initialize(
            _creator,
            _defaultRoyalty,
            _defaultTokenManager,
            _contractURI,
            _name,
            _symbol,
            editionsMetadataRendererAddress,
            trustedForwarder,
            mintManagerAddress
        );
        return clone;
    }

    /**
     * @dev Initialize ERC721Edition collection, deployed via Create2 AND create first edition on it
     * @param _creator Creator/owner of contract
     * @param _defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param _editionInfo First edition's info
     * @param _size First edition's size
     * @param salt Salt used to uniquely deploy collection (via Create2)
     */
    function setupERC721EditionCollectionWithEdition(
        address _creator,
        IRoyaltyManager.Royalty memory _defaultRoyalty,
        address _defaultTokenManager,
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        IEditionsMetadataRenderer.TokenEditionInfo memory _editionInfo,
        uint256 _size,
        bytes32 salt // generate off-chain
    ) external returns (address) {
        address clone = Clones.cloneDeterministic(erc721EditionsImplementation, salt);
        ERC721Editions(clone).initialize(
            address(this),
            _defaultRoyalty,
            _defaultTokenManager,
            _contractURI,
            _name,
            _symbol,
            editionsMetadataRendererAddress,
            trustedForwarder,
            mintManagerAddress
        );
        ERC721Editions(clone).createEdition(
            abi.encode(_editionInfo),
            _size,
            _defaultTokenManager // apply default token manager to edition as well
        );
        ERC721Editions(clone).transferOwnership(_creator);
        return clone;
    }

    /**
     * @dev Initialize ERC721SingleEdition collection, deployed via Create2
     * @param _creator Creator/owner of contract
     * @param _defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param _editionInfo Single edition's info
     * @param _size Single edition's size
     * @param salt Salt used to uniquely deploy collection (via Create2)
     */
    function setupERC721SingleEditionCollection(
        address _creator,
        IRoyaltyManager.Royalty memory _defaultRoyalty,
        address _defaultTokenManager,
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        IEditionsMetadataRenderer.TokenEditionInfo memory _editionInfo,
        uint256 _size,
        bytes32 salt // generate off-chain
    ) external returns (address) {
        address clone = Clones.cloneDeterministic(erc721SingleEditionImplementation, salt);
        ERC721SingleEdition(clone).initialize(
            _creator,
            _defaultRoyalty,
            _defaultTokenManager,
            _contractURI,
            _name,
            _symbol,
            abi.encode(_editionInfo),
            _size,
            editionsMetadataRendererAddress,
            trustedForwarder,
            mintManagerAddress
        );
        return clone;
    }

    /**
     * @dev Initialize ERC721General collection, deployed via Create2
     * @param _creator Creator/owner of contract
     * @param _defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param baseUri Collection's base uri
     * @param limitSupply Collection's limit supply
     * @param salt Salt used to uniquely deploy collection (via Create2)
     */
    function setupERC721GeneralCollection(
        address _creator,
        IRoyaltyManager.Royalty memory _defaultRoyalty,
        address _defaultTokenManager,
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        string calldata baseUri,
        uint256 limitSupply,
        bytes32 salt // generate off-chain
    ) external returns (address) {
        address clone = Clones.cloneDeterministic(erc721GeneralImplementation, salt);
        ERC721General(clone).initialize(
            _creator,
            _contractURI,
            _defaultRoyalty,
            _defaultTokenManager,
            _name,
            _symbol,
            trustedForwarder,
            mintManagerAddress,
            baseUri,
            limitSupply
        );
        return clone;
    }

    /**
     * @dev Predict Create2 deployed ERC721Edition collection
     * @param salt Salt used to uniquely deploy collection
     */
    function predictERC721EditionCollectionAddress(bytes32 salt) external view returns (address) {
        return Clones.predictDeterministicAddress(erc721EditionsImplementation, salt);
    }

    /**
     * @dev Predict Create2 deployed ERC721SingleEdition collection
     * @param salt Salt used to uniquely deploy collection
     */
    function predictERC721SingleEditionCollectionAddress(bytes32 salt) external view returns (address) {
        return Clones.predictDeterministicAddress(erc721SingleEditionImplementation, salt);
    }

    /**
     * @dev Predict Create2 deployed ERC721General collection
     * @param salt Salt used to uniquely deploy collection
     */
    function predictERC721GeneralCollectionAddress(bytes32 salt) external view returns (address) {
        return Clones.predictDeterministicAddress(erc721GeneralImplementation, salt);
    }
}