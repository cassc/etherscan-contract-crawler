// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "IWalletFactory.sol";
import "GamingWallet.sol";
import "NFTRental.sol";
import "IGamingWallet.sol";
import "IMissionManager.sol";
import "EnumerableSet.sol";
import "AccessManager.sol";

contract WalletFactory is IWalletFactory, AccessManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public immutable missionManager;
    address public rentalPool;
    address public dappGuardRegistry;
    address public revenueManager;

    mapping(address => address) public ownerGamingWallet;
    mapping(string => EnumerableSet.AddressSet) private collectionForDapp;

    modifier onlyMissionManager() {
        require(
            msg.sender == missionManager,
            "Only Mission Manager is authorized"
        );
        _;
    }

    constructor(
        address _rentalPool,
        address _dappGuardRegistry,
        address _missionManager,
        address _revenueManager,
        IRoleRegistry _roleRegistry
    ) {
        rentalPool = _rentalPool;
        dappGuardRegistry = _dappGuardRegistry;
        missionManager = _missionManager;
        revenueManager = _revenueManager;
        setRoleRegistry(_roleRegistry);
    }

    function createWallet() external override {
        _createWallet(msg.sender);
    }

    function createWallet(address _owner) external override {
        _createWallet(_owner);
    }

    function resetTenantGamingWallet(address _tenant)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        require(
            IMissionManager(missionManager)
                .getTenantOngoingMissionUuid(_tenant)
                .length == 0,
            "Tenant has ongoing mission"
        );
        ownerGamingWallet[_tenant] = address(0x0);
    }

    function changeRentalPoolAddress(address _rentalPool)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        rentalPool = _rentalPool;
    }

    function changeDappGuardRegistryAddress(address _dappGuardRegistry)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        dappGuardRegistry = _dappGuardRegistry;
    }

    function changeRevenueManagerAddress(address _revenueManager)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        revenueManager = _revenueManager;
    }

    function addCollectionForDapp(string calldata _dappId, address _collection)
        external
        override
        onlyRole(Roles.MISSION_CONFIGURATOR)
    {
        collectionForDapp[_dappId].add(_collection);
    }

    function removeCollectionForDapp(
        string calldata _dappId,
        address _collection
    ) external override onlyRole(Roles.MISSION_CONFIGURATOR) {
        collectionForDapp[_dappId].remove(_collection);
    }

    function verifyCollectionForUniqueDapp(
        string calldata _dappId,
        address[] calldata _collections
    ) external view override returns (bool uniqueDapp) {
        for (uint256 i; i < _collections.length; i++) {
            if (!collectionForDapp[_dappId].contains(_collections[i])) {
                return false;
            }
        }
        return true;
    }

    function getGamingWallet(address _owner)
        external
        view
        override
        returns (address gamingWalletAddress)
    {
        return ownerGamingWallet[_owner];
    }

    function hasGamingWallet(address _owner)
        external
        view
        override
        returns (bool hasWallet)
    {
        return ownerGamingWallet[_owner] != address(0x0);
    }

    function _createWallet(address _owner) internal {
        require(
            ownerGamingWallet[_owner] == address(0),
            "Owner already has a wallet!"
        );
        GamingWallet newGamingWallet = new GamingWallet(
            missionManager,
            rentalPool,
            dappGuardRegistry,
            _owner,
            address(this),
            revenueManager
        );
        ownerGamingWallet[_owner] = address(newGamingWallet);
        emit WalletCreated(_owner, address(newGamingWallet));
    }
}