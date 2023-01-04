// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

import {Pausable} from "./abstract/Pausable.sol";
import {Controllable} from "./abstract/Controllable.sol";
import {IMetadataResolver} from "./interfaces/IMetadataResolver.sol";
import {IMetadata} from "./interfaces/IMetadata.sol";
import {IControllable} from "./interfaces/IControllable.sol";

/// @title Metadata - Resolves metadata URIs
/// @notice Converts contract addresses and token IDs to metadata URIs. Allows
/// project owners to set custom URIs and resolver contracts.
contract Metadata is IMetadata, Controllable, Pausable {
    using Strings for uint256;
    using Strings for address;

    string public constant NAME = "Metadata";
    string public constant VERSION = "0.0.1";

    address public creators;

    string public tokenURIBase;
    string public contractURIBase;
    address public defaultCollectionOwner;

    // token contract address => owner account address
    mapping(address => address) public collectionOwners;
    // tokenId => URI
    mapping(uint256 => string) public customURIs;
    // tokenId => resolver contract
    mapping(uint256 => IMetadataResolver) public customResolvers;

    constructor(
        address _controller,
        string memory _tokenURIBase,
        string memory _contractURIBase,
        address _defaultCollectionOwner
    ) Controllable(_controller) {
        tokenURIBase = _tokenURIBase;
        contractURIBase = _contractURIBase;
        defaultCollectionOwner = _defaultCollectionOwner;

        emit SetTokenURIBase("", _tokenURIBase);
        emit SetContractURIBase("", _contractURIBase);
        emit SetDefaultCollectionOwner(address(0), _defaultCollectionOwner);
    }

    modifier onlyCreators() {
        if (msg.sender != creators) {
            revert Forbidden();
        }
        _;
    }

    /// @inheritdoc IMetadata
    function contractURI(address _contract) external view override returns (string memory) {
        return string.concat(contractURIBase, _contract.toHexString(), ".json");
    }

    /// @inheritdoc IMetadata
    function uri(uint256 tokenId) external view override returns (string memory) {
        IMetadataResolver customResolver = customResolvers[tokenId];
        if (address(customResolver) != address(0)) {
            return customResolver.uri(tokenId);
        }

        string memory customURI = customURIs[tokenId];
        if (bytes(customURI).length != 0) {
            return customURI;
        }

        return string.concat(tokenURIBase, tokenId.toString(), ".json");
    }

    /// @inheritdoc IMetadata
    function owner(address collection) external view override returns (address) {
        address _owner = collectionOwners[collection];
        if (_owner != address(0)) return _owner;
        return defaultCollectionOwner;
    }

    /// @inheritdoc IMetadata
    function setCustomURI(uint256 tokenId, string memory customURI) external override onlyCreators whenNotPaused {
        customURIs[tokenId] = customURI;
        emit SetCustomURI(tokenId, customURI);
    }

    /// @inheritdoc IMetadata
    function setCustomResolver(uint256 tokenId, IMetadataResolver customResolver)
        external
        override
        onlyCreators
        whenNotPaused
    {
        customResolvers[tokenId] = customResolver;
        emit SetCustomResolver(tokenId, customResolver);
    }

    /// @inheritdoc IMetadata
    function setDefaultCollectionOwner(address _owner) external override onlyController {
        emit SetDefaultCollectionOwner(defaultCollectionOwner, _owner);
        defaultCollectionOwner = _owner;
    }

    /// @inheritdoc IMetadata
    function setCollectionOwner(address collection, address _owner) external override onlyController {
        collectionOwners[collection] = _owner;
        emit SetCollectionOwner(collection, _owner);
    }

    /// @inheritdoc IMetadata
    function setTokenURIBase(string memory _tokenURIBase) external override onlyController {
        emit SetTokenURIBase(tokenURIBase, _tokenURIBase);
        tokenURIBase = _tokenURIBase;
    }

    /// @inheritdoc IMetadata
    function setContractURIBase(string memory _contractURIBase) external override onlyController {
        emit SetContractURIBase(contractURIBase, _contractURIBase);
        contractURIBase = _contractURIBase;
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address _contract)
        external
        override (Controllable, IControllable)
        onlyController
    {
        if (_contract == address(0)) revert ZeroAddress();
        else if (_name == "creators") _setCreators(_contract);
        else revert InvalidDependency(_name);
    }

    function _setCreators(address _creators) internal {
        emit SetCreators(creators, _creators);
        creators = _creators;
    }

    function pause() external override onlyController {
        _pause();
    }

    function unpause() external override onlyController {
        _unpause();
    }
}