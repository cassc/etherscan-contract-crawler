//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "./IWagdieWorld.sol";

import "../external/IWagdie.sol";
import "../external/ITokensOfConcord.sol";

import "../../shared/UtilitiesUpgradeable.sol";

abstract contract WagdieWorldState is IWagdieWorld, ERC721HolderUpgradeable, UtilitiesUpgradeable {

    bytes32 public constant LOCATION_CHANGER_ROLE = keccak256("LOCATION_CHANGER_ROLE");
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    event LocationAdded(uint64 locationId, string name, int32 xCoordinate, int32 yCoordinate);
    event LocationUpdated(uint64 locationId, string name, int32 xCoordinate, int32 yCoordinate);
    event LocationRemoved(uint64 locationId);
    event LocationOwnerChanged(uint64 locationId, address oldOwner, address newOwner);
    event LocationNftLockedChanged(uint64 locationId, bool areNftsLocked);

    event StakingEnabledChanged(bool isStakingEnabled);

    event WagdieStaked(uint16 wagdieId, address owner, uint64 locationId);
    event WagdieUnstaked(uint16 wagdieId, address owner, uint64 locationId);
    event WagdieLocationChanged(uint16 wagdieId, uint64 oldLocationId, uint64 newLocationId);
    event WagdieBurned(uint16 wagdieId, uint64 locationId);

    IWagdie public wagdie;
    ITokensOfConcord public tokensOfConcord;

    // The next location ID that will be assigned to a new location.
    uint64 public locationIdCur;

    // Maps a location Id to its info
    mapping(uint64 => LocationInfo) public locationIdToInfo;
    mapping(uint64 => EnumerableSetUpgradeable.UintSet) internal locationIdToStakedSet;

    mapping(uint16 => WagdieInfo) public wagdieIdToInfo;

    // Indicates if staking is enabled globally.
    bool public isStakingEnabled;

    function __WagdieWorldState_init() internal initializer {
        UtilitiesUpgradeable.__Utilities_init();
        ERC721HolderUpgradeable.__ERC721Holder_init();

        locationIdCur = 1;
    }
}

struct LocationInfo {
    // Slot 1
    // The name of the location.
    string name;
    // Slot 2
    // The owner of this location. If the 0 address, owned by the contract owner.
    address locationOwner;
    int32 xCoordinate;
    int32 yCoordinate;
    // Slot 3
    // Indicates if this is still a valid location.
    bool isLocationActive;
    // Indicates if Nfts are temporarily locked in this location.
    // Only set by the location owner (or contract owner if no location owner).
    bool areNftsLocked;
    uint240 emptySpace1;
}

struct WagdieInfo {
    // Slot 1
    // Current id of the location the wagdie is at. If 0, wagdie is not staked
    uint64 locationIdCur;
    // The true owner of the wagdie.
    address owner;
    uint32 emptySpace;
}