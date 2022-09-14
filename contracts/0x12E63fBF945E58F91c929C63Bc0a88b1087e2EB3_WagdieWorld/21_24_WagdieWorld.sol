//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./WagdieWorldSettings.sol";

contract WagdieWorld is Initializable, WagdieWorldSettings {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function initialize() external initializer {
        WagdieWorldSettings.__WagdieWorldSettings_init();
    }

    function stakeWagdies(
        StakeWagdieParams[] calldata _stakeWagdieParams)
    external
    {
        require(isStakingEnabled, "Staking is not enabled");
        require(_stakeWagdieParams.length > 0, "No parameters given");

        for(uint256 i = 0; i < _stakeWagdieParams.length; i++) {
            _stakeWagdie(_stakeWagdieParams[i].wagdieId, _stakeWagdieParams[i].locationId);
        }
    }

    function _stakeWagdie(
        uint16 _wagdieId,
        uint64 _locationId)
    private
    requireActiveLocation(_locationId)
    requireNftUnlockedAtLocation(_locationId)
    {
        wagdie.safeTransferFrom(msg.sender, address(this), _wagdieId);

        locationIdToStakedSet[_locationId].add(_wagdieId);

        wagdieIdToInfo[_wagdieId].locationIdCur = _locationId;
        wagdieIdToInfo[_wagdieId].owner = msg.sender;

        emit WagdieStaked(_wagdieId, msg.sender, _locationId);
    }

    function unstakeWagdies(
        UnstakeWagdieParams[] calldata _unstakeWagdieParams)
    external
    {
        require(_unstakeWagdieParams.length > 0, "No parameters given");

        for(uint256 i = 0; i < _unstakeWagdieParams.length; i++) {
            _unstakeWagdie(_unstakeWagdieParams[i].wagdieId);
        }
    }

    function _unstakeWagdie(
        uint16 _wagdieId)
    private
    {
        uint64 _locationId = wagdieIdToInfo[_wagdieId].locationIdCur;
        require(_locationId > 0, "Wagdie is not staked");

        require(!locationIdToInfo[_locationId].isLocationActive
            || !locationIdToInfo[_locationId].areNftsLocked, "Nfts are locked at this location");

        require(msg.sender == wagdieIdToInfo[_wagdieId].owner, "Not owner of Wagdie");

        delete wagdieIdToInfo[_wagdieId];

        locationIdToStakedSet[_locationId].remove(_wagdieId);

        wagdie.safeTransferFrom(address(this), msg.sender, _wagdieId);

        emit WagdieUnstaked(_wagdieId, msg.sender, _locationId);
    }

    function changeWagdieLocations(
        ChangeWagdieLocationParams[] calldata _changeWagdieLocationParams)
    external
    {
        require(isStakingEnabled, "Changing locations is not enabled");
        require(_changeWagdieLocationParams.length > 0, "No parameters given");

        for(uint256 i = 0; i < _changeWagdieLocationParams.length; i++) {
            _changeWagdieLocations(
                _changeWagdieLocationParams[i].wagdieId,
                _changeWagdieLocationParams[i].newLocationId);
        }
    }

    function _changeWagdieLocations(
        uint16 _wagdieId,
        uint64 _newLocationId)
    private
    requireActiveLocation(_newLocationId)
    requireNftUnlockedAtLocation(_newLocationId)
    {
        uint64 _oldLocationId = wagdieIdToInfo[_wagdieId].locationIdCur;

        require(!locationIdToInfo[_oldLocationId].isLocationActive
            || !locationIdToInfo[_oldLocationId].areNftsLocked, "Nfts are locked at old location");

        require(_oldLocationId != _newLocationId, "Can't change to same location");

        require(msg.sender == wagdieIdToInfo[_wagdieId].owner
            || hasRole(OWNER_ROLE, msg.sender)
            || hasRole(LOCATION_CHANGER_ROLE, msg.sender), "Unauthorized to change Wagdie location");

        locationIdToStakedSet[_oldLocationId].remove(_wagdieId);
        locationIdToStakedSet[_newLocationId].add(_wagdieId);

        wagdieIdToInfo[_wagdieId].locationIdCur = _newLocationId;

        emit WagdieLocationChanged(
            _wagdieId,
            _oldLocationId,
            _newLocationId);
    }

    function burnWagdie(
        BurnWagdieParams calldata _params)
    external
    requireActiveLocation(_params.locationId)
    isLocationOrContractOwner(_params.locationId)
    {
        uint256[] memory _wagdieIds = locationIdToStakedSet[_params.locationId].values();
        uint256 _wagdiesAtLocation = _wagdieIds.length;

        require(_params.maxAmountToBurn >= _params.minAmountToBurn
            && _params.maxAmountToBurn > 0
            && _wagdiesAtLocation >= _params.minAmountToBurn
            && _wagdiesAtLocation >= _params.maxAmountToBurn, "Bad min and max values");

        uint256 _randomNumber = _getPseudoRandomNumber();

        uint16 _amountToBurn = _chooseAmountToBurn(
            _params.minAmountToBurn,
            _params.maxAmountToBurn,
            _randomNumber
        );

        for(uint256 i = 0; i < _amountToBurn; i++) {
            _randomNumber = uint256(keccak256(abi.encodePacked(_randomNumber, _randomNumber)));

            uint256 _selectedWagdieIndex = _randomNumber % _wagdiesAtLocation;

            uint16 _burnedWagdieId = uint16(_wagdieIds[_selectedWagdieIndex]);

            locationIdToStakedSet[_params.locationId].remove(_burnedWagdieId);

            delete wagdieIdToInfo[_burnedWagdieId];

            // Remove from in memory array by moving the last item to this index
            _wagdieIds[_selectedWagdieIndex] = _wagdieIds[_wagdiesAtLocation - 1];
            _wagdiesAtLocation--;

            // Finally, burn the wagdie.
            wagdie.safeTransferFrom(address(this), BURN_ADDRESS, _burnedWagdieId);

            emit WagdieBurned(_burnedWagdieId, _params.locationId);
        }
    }

    function burnSpecificWagdie(
        uint16 _wagdieId)
    external
    {
        uint64 _locationId = wagdieIdToInfo[_wagdieId].locationIdCur;
        require(_locationId > 0, "Wagdie is not staked");
        
        require(msg.sender == locationIdToInfo[_locationId].locationOwner
            || hasRole(OWNER_ROLE, msg.sender), "Not location or contract owner");
        
        delete wagdieIdToInfo[_wagdieId];

        locationIdToStakedSet[_locationId].remove(_wagdieId);

        wagdie.safeTransferFrom(address(this), BURN_ADDRESS, _wagdieId);

        emit WagdieBurned( _wagdieId, _locationId);
    }

    function mintConcordsToLocation(
        MintConcordsToLocationParams calldata _params)
    external
    requireActiveLocation(_params.locationId)
    isLocationOrContractOwner(_params.locationId)
    {
        uint256[] memory _wagdieIds = locationIdToStakedSet[_params.locationId].values();

        address[] memory _owners = new address[](_wagdieIds.length);

        require(_wagdieIds.length > 0, "No wagdies at location");

        for(uint256 i = 0; i < _wagdieIds.length; i++) {
            uint16 _wagdieId = uint16(_wagdieIds[i]);

            _owners[i] = wagdieIdToInfo[_wagdieId].owner;
        }

        tokensOfConcord.bestowTokens(_owners, _params.itemId, _params.amount);
    }

    function _chooseAmountToBurn(
        uint16 _min,
        uint16 _max,
        uint256 _randomNumber)
    private
    pure
    returns(uint16)
    {
        if(_min == _max) {
            return _max;
        }

        uint256 _randomChoice = _randomNumber % (_max - _min + 1);

        return uint16(_min + _randomChoice);
    }

    // This random number is gameable, but only used in functions controlled by admins.
    function _getPseudoRandomNumber() private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number, msg.sender)));
    }
}

struct StakeWagdieParams {
    // Slot1 (80/256 used)
    uint16 wagdieId;
    uint64 locationId;
}

struct UnstakeWagdieParams {
    // Slot1 (16/256 used)
    uint16 wagdieId;
}

struct ChangeWagdieLocationParams {
    // Slot 1 (80/256 used)
    uint16 wagdieId;
    uint64 newLocationId;
}

struct BurnWagdieParams {
    // Slot 1 (96/256 used)
    uint64 locationId;
    // The minimum amount of wagdies from this location that will be burnt.
    uint16 minAmountToBurn;
    // The maximum amount of wagdies from this location that will be burnt.
    // Capped at the number of wagdies at this location.
    // If min == max, the exact number of wagdies will be burnt.
    uint16 maxAmountToBurn;
}

struct MintConcordsToLocationParams {
    // Slot 1 (128/256 used)
    uint64 locationId;
    uint32 amount;
    uint32 itemId;
}