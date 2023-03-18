// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { CollectionStorage } from '../collectionStorage/CollectionStorage.sol';
import { CollectionProxy } from '../collectionProxy/CollectionProxy.sol';

import { CollectionFactoryAutoProxy } from './CollectionFactoryAutoProxy.sol';
import { StorageBase } from '../StorageBase.sol';
import { Ownable } from '../Ownable.sol';

import { IFactoryGovernedProxy } from './IFactoryGovernedProxy.sol';
import { ICollectionManager } from '../interfaces/ICollectionManager.sol';
import { IStorageBase } from '../interfaces/IStorageBase.sol';
import { IGovernedContract } from '../interfaces/IGovernedContract.sol';
import { ICollectionFactory } from './ICollectionFactory.sol';
import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';

contract CollectionFactoryStorage is StorageBase {
    address private collectionManagerProxy;
    address private collectionManagerHelperProxy;

    address[] private collectionProxyAddresses;

    constructor(address _collectionManagerProxy, address _collectionManagerHelperProxy) public {
        collectionManagerProxy = _collectionManagerProxy;
        collectionManagerHelperProxy = _collectionManagerHelperProxy;
    }

    function getCollectionManagerProxy() external view returns (address) {
        return collectionManagerProxy;
    }

    function getCollectionManagerHelperProxy() external view returns (address) {
        return collectionManagerHelperProxy;
    }

    function getCollectionProxyAddress(uint256 _i) external view returns (address) {
        return collectionProxyAddresses[_i];
    }

    function getCollectionProxyAddressesLength() external view returns (uint256) {
        return collectionProxyAddresses.length;
    }

    function pushCollectionProxyAddress(address collectionProxyAddress) external requireOwner {
        collectionProxyAddresses.push(collectionProxyAddress);
    }

    function popCollectionProxyAddress() external requireOwner {
        collectionProxyAddresses.pop();
    }

    function setCollectionProxyAddresses(
        uint256 _i,
        address collectionProxyAddress
    ) external requireOwner {
        collectionProxyAddresses[_i] = collectionProxyAddress;
    }

    function setCollectionManagerProxy(address _collectionManagerProxy) external requireOwner {
        collectionManagerProxy = _collectionManagerProxy;
    }

    function setCollectionManagerHelperProxy(
        address _collectionManagerHelperProxy
    ) external requireOwner {
        collectionManagerHelperProxy = _collectionManagerHelperProxy;
    }
}

contract CollectionFactory is Ownable, CollectionFactoryAutoProxy, ICollectionFactory {
    bool public initialized = false;
    CollectionFactoryStorage public _storage;

    constructor(address _proxy) public CollectionFactoryAutoProxy(_proxy, address(this)) {}

    function setSporkProxy(address payable _sporkProxy) external onlyOwner {
        IFactoryGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // Initialize contract. This function can only be called once
    function initialize(
        address _collectionManagerProxy,
        address _collectionManagerHelperProxy
    ) external onlyOwner {
        require(!initialized, 'CollectionFactory: already initialized');
        _storage = new CollectionFactoryStorage(
            _collectionManagerProxy,
            _collectionManagerHelperProxy
        );
        initialized = true;
    }

    // This function is called in order to upgrade to a new CollectionFactory implementation
    function destroy(IGovernedContract _newImpl) external requireProxy {
        IStorageBase(address(_storage)).setOwner(address(_newImpl));

        // Self destruct
        _destroy(_newImpl);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    function collectionManagerImpl() private view returns (address _collectionManagerImpl) {
        _collectionManagerImpl = address(
            IGovernedProxy_New(address(uint160(_storage.getCollectionManagerProxy())))
                .implementation()
        );
    }

    // permissioned functions
    function deploy(
        string calldata baseURI,
        string calldata name,
        string calldata symbol,
        address mintFeeERC20AssetProxy,
        uint256 mintFeeERC20,
        uint256[4] calldata mintFeeETH
    )
        external
        // mintFeeETH = [baseMintFeeETH, ethMintFeeIncreaseInterval, ethMintsCountThreshold, ethMintFeeGrowthRateBps]
        onlyOwner
    {
        require(mintFeeETH[2] > 0, 'CollectionFactory: ethMintsCountThreshold should be > 0');
        address collectionStorageAddress = address(
            new CollectionStorage(
                _storage.getCollectionManagerProxy(),
                _storage.getCollectionManagerHelperProxy(),
                baseURI,
                name,
                symbol
            )
        );

        address collectionProxyAddress;

        // Deploy CollectionProxy via CREATE2
        bytes memory bytecode = abi.encodePacked(
            type(CollectionProxy).creationCode,
            abi.encode(_storage.getCollectionManagerProxy()),
            abi.encode(_storage.getCollectionManagerHelperProxy())
        );
        bytes32 salt = keccak256(abi.encode(_storage.getCollectionProxyAddressesLength() + 1));
        assembly {
            collectionProxyAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Register CollectionProxy, and CollectionStorage into CollectionManager
        registerCollection(
            collectionProxyAddress,
            collectionStorageAddress,
            baseURI,
            name,
            symbol,
            mintFeeERC20AssetProxy,
            mintFeeERC20,
            mintFeeETH
        );
    }

    function registerCollection(
        address collectionProxyAddress,
        address collectionStorageAddress,
        string memory baseURI,
        string memory name,
        string memory symbol,
        address mintFeeERC20AssetProxy,
        uint256 mintFeeERC20,
        uint256[4] memory mintFeeETH
    ) private {
        // Register CollectionProxy, and CollectionStorage into CollectionManager
        ICollectionManager(collectionManagerImpl()).register(
            collectionProxyAddress,
            collectionStorageAddress,
            mintFeeERC20AssetProxy,
            mintFeeERC20,
            mintFeeETH
            // mintFeeETH = [baseMintFeeETH, ethMintFeeIncreaseInterval, ethMintsCountThreshold, ethMintFeeGrowthRateBps]
        );

        _storage.pushCollectionProxyAddress(collectionProxyAddress);

        // Emit collection creation event
        IFactoryGovernedProxy(address(uint160(proxy))).emitCollectionCreated(
            collectionProxyAddress,
            collectionStorageAddress,
            baseURI,
            name,
            symbol,
            _storage.getCollectionProxyAddressesLength()
        );
    }

    function getCollectionProxyAddress(uint256 _i) external view returns (address) {
        return _storage.getCollectionProxyAddress(_i);
    }

    function getCollectionManagerProxy() external view returns (address) {
        return _storage.getCollectionManagerProxy();
    }
}