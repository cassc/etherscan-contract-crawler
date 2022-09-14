//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./WagdieWorldContracts.sol";

abstract contract WagdieWorldSettings is WagdieWorldContracts {

    function __WagdieWorldSettings_init() internal initializer {
        WagdieWorldContracts.__WagdieWorldContracts_init();

        _updateIsStakingEnabled(true);
    }

    function updateIsStakingEnabled(bool _isStakingEnabled) public requiresRole(OWNER_ROLE) {
        _updateIsStakingEnabled(_isStakingEnabled);
    }

    function _updateIsStakingEnabled(bool _isStakingEnabled) private {
        isStakingEnabled = _isStakingEnabled;

        emit StakingEnabledChanged(isStakingEnabled);
    }

    // Adds a new location to the contract. Must be called by the contract owner.
    // New locations are automatically activated.
    function addLocation(AddLocationParams calldata _addLocationParams) external requiresRole(OWNER_ROLE) {
        uint64 _locationId = locationIdCur;
        locationIdCur++;

        locationIdToInfo[_locationId].name = _addLocationParams.name;
        locationIdToInfo[_locationId].locationOwner = _addLocationParams.locationOwner;
        locationIdToInfo[_locationId].xCoordinate = _addLocationParams.xCoordinate;
        locationIdToInfo[_locationId].yCoordinate = _addLocationParams.yCoordinate;
        locationIdToInfo[_locationId].isLocationActive = true;

        emit LocationAdded(
            _locationId,
            _addLocationParams.name,
            _addLocationParams.xCoordinate,
            _addLocationParams.yCoordinate);

        emit LocationNftLockedChanged(
            _locationId,
            false);

        if(_addLocationParams.locationOwner != address(0)) {
            emit LocationOwnerChanged(
                _locationId,
                address(0),
                _addLocationParams.locationOwner);
        }
    }

    function updateLocation(uint64 _locationId, AddLocationParams calldata _addLocationParams) external requiresRole(OWNER_ROLE) {
        locationIdToInfo[_locationId].name = _addLocationParams.name;
        locationIdToInfo[_locationId].locationOwner = _addLocationParams.locationOwner;
        locationIdToInfo[_locationId].xCoordinate = _addLocationParams.xCoordinate;
        locationIdToInfo[_locationId].yCoordinate = _addLocationParams.yCoordinate;
        locationIdToInfo[_locationId].isLocationActive = true;

        emit LocationUpdated(
            _locationId,
            _addLocationParams.name,
            _addLocationParams.xCoordinate,
            _addLocationParams.yCoordinate);

        if(_addLocationParams.locationOwner != address(0)) {
            emit LocationOwnerChanged(
                _locationId,
                address(0),
                _addLocationParams.locationOwner);
        }
    }

    function changeLocationOwner(
        ChangeLocationOwnerParams calldata _changeLocationParams)
    external
    requireActiveLocation(_changeLocationParams.locationId)
    isLocationOrContractOwner(_changeLocationParams.locationId)
    {
        address _oldOwner = locationIdToInfo[_changeLocationParams.locationId].locationOwner;
        require(_oldOwner != _changeLocationParams.newOwner, "Location owner did not change");

        locationIdToInfo[_changeLocationParams.locationId].locationOwner = _changeLocationParams.newOwner;

        emit LocationOwnerChanged(
            _changeLocationParams.locationId,
            _oldOwner,
            _changeLocationParams.newOwner);
    }

    function removeLocation(
        uint64 _locationId)
    external
    requireActiveLocation(_locationId)
    isLocationOrContractOwner(_locationId)
    {
        locationIdToInfo[_locationId].isLocationActive = false;

        emit LocationRemoved(_locationId);
    }

    function updateNftsLocked(
        UpdateNftsLocked calldata _updateNftsLockedParams)
    external
    requireActiveLocation(_updateNftsLockedParams.locationId)
    isLocationOrContractOwner(_updateNftsLockedParams.locationId)
    {
        locationIdToInfo[_updateNftsLockedParams.locationId].areNftsLocked = _updateNftsLockedParams.areNftsLocked;

        emit LocationNftLockedChanged(
            _updateNftsLockedParams.locationId,
            _updateNftsLockedParams.areNftsLocked);
    }


    modifier requireActiveLocation(uint64 _locationId) {
        require(locationIdToInfo[_locationId].isLocationActive, "Location DNE or has been removed");

        _;
    }

    modifier requireNftUnlockedAtLocation(uint64 _locationId) {
        require(!locationIdToInfo[_locationId].areNftsLocked, "Nfts are locked for location");

        _;
    }

    modifier isLocationOrContractOwner(uint64 _locationId) {
        require(msg.sender == locationIdToInfo[_locationId].locationOwner
            || hasRole(OWNER_ROLE, msg.sender), "Not location or contract owner");

        _;
    }
}

struct AddLocationParams {
    // Slot 1
    string name;
    // Slot 2 (224/256 used)
    address locationOwner;
    int32 xCoordinate;
    int32 yCoordinate;
}

struct ChangeLocationOwnerParams {
    // Slot 1 (224/256 used)
    uint64 locationId;
    address newOwner;
}

struct UpdateNftsLocked {
    // Slot 1 (72/256 used)
    uint64 locationId;
    bool areNftsLocked;
}