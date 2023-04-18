// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { ICollectionStorage } from '../interfaces/ICollectionStorage.sol';

interface IERC721ManagerStorage {
    // Getter functions
    //
    function getCollectionStorage(
        address collectionProxy
    ) external view returns (ICollectionStorage);

    function getCollectionProxy(uint256 index) external view returns (address);

    function getCollectionsCount() external view returns (uint256);

    function getMAX_SUPPLY(address collectionProxy) external view returns (uint256);

    function getMAX_ETH_MINTS(address collectionProxy) external view returns (uint256);

    function getMAX_WHITELIST_MINT_PER_ADDRESS(
        address collectionProxy
    ) external view returns (uint256);

    function getMAX_PUBLIC_MINT_PER_ADDRESS(
        address collectionProxy
    ) external view returns (uint256);

    function getBlockStartWhitelistPhase(address collectionProxy) external view returns (uint256);

    function getBlockEndWhitelistPhase(address collectionProxy) external view returns (uint256);

    function getBlockStartPublicPhase(address collectionProxy) external view returns (uint256);

    function getBlockEndPublicPhase(address collectionProxy) external view returns (uint256);

    function isWhitelisted(address collectionProxy, address _user) external view returns (bool);

    function getWhitelistIndex(
        address collectionProxy,
        address _user
    ) external view returns (uint256);

    function getWhitelistedUsersCount(address collectionProxy) external view returns (uint256);

    function getWhitelistedUserByIndex(
        address collectionProxy,
        uint256 _index
    ) external view returns (address _whitelistedUser);

    function getWhitelistMintCount(
        address collectionProxy,
        address _address
    ) external view returns (uint256);

    function getPublicMintCount(
        address collectionProxy,
        address _address
    ) external view returns (uint256);

    function getOwnerMintCount(address collectionProxy) external view returns (uint256);

    function getMintFeeERC20AssetProxy(address collectionProxy) external view returns (address);

    function getMintFeeERC20(address collectionProxy) external view returns (uint256);

    function getBaseMintFeeETH(address collectionProxy) external view returns (uint256);

    function getETHMintFeeGrowthRateBps(address collectionProxy) external view returns (uint256);

    function getETHMintsCountThreshold(address collectionProxy) external view returns (uint256);

    function getETHMintsCount(address collectionProxy) external view returns (uint256);

    function getLastETHMintFeeAboveThreshold(
        address collectionProxy
    ) external view returns (uint256);

    function getMintFeeRecipient() external view returns (address _mintFeeRecipient);

    function getFeeDenominator() external view returns (uint96);

    // Setter functions
    //
    function setCollectionStorage(address collectionProxy, address _collectionStorage) external;

    function pushCollectionProxy(address collectionProxy) external;

    function popCollectionProxy() external;

    function setCollectionProxy(uint256 index, address collectionProxy) external;

    function setMAX_SUPPLY(address collectionProxy, uint256 _value) external;

    function setMAX_ETH_MINTS(address collectionProxy, uint256 _value) external;

    function setMAX_WHITELIST_MINT_PER_ADDRESS(address collectionProxy, uint256 _value) external;

    function setMAX_PUBLIC_MINT_PER_ADDRESS(address collectionProxy, uint256 _value) external;

    function setWhitelistPhase(
        address collectionProxy,
        uint256 _blockStartWhitelistPhase,
        uint256 _blockEndWhitelistPhase
    ) external;

    function setPublicPhase(
        address collectionProxy,
        uint256 _blockStartPublicPhase,
        uint256 _blockEndPublicPhase
    ) external;

    function setWhitelisted(address collectionProxy, address _user, bool _isWhitelisted) external;

    function setWhitelistMintCount(
        address collectionProxy,
        address _address,
        uint256 _amount
    ) external;

    function setPublicMintCount(
        address collectionProxy,
        address _address,
        uint256 _amount
    ) external;

    function setOwnerMintCount(address collectionProxy, uint256 _amount) external;

    function setMintFeeERC20AssetProxy(
        address collectionProxy,
        address _mintFeeERC20AssetProxy
    ) external;

    function setMintFeeERC20(address collectionProxy, uint256 _mintFeeERC20) external;

    function setMintFeeETH(address collectionProxy, uint256[] memory _mintFeeETH) external;

    function setBaseMintFeeETH(address collectionProxy, uint256 _baseMintFeeETH) external;

    function setETHMintFeeGrowthRateBps(
        address collectionProxy,
        uint256 _ethMintFeeGrowthRateBps
    ) external;

    function setETHMintsCountThreshold(
        address collectionProxy,
        uint256 _ethMintsCountThreshold
    ) external;

    function setETHMintsCount(address collectionProxy, uint256 _ethMintsCount) external;

    function setLastETHMintFeeAboveThreshold(
        address collectionProxy,
        uint256 _lastETHMintFeeAboveThreshold
    ) external;

    function setMintFeeRecipient(address _mintFeeRecipient) external;

    function setFeeDenominator(uint96 value) external;
}