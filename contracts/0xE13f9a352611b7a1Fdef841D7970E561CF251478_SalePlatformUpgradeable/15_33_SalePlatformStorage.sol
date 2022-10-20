// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IQuantumArt.sol";
import "./interfaces/IQuantumMintPass.sol";
import "./interfaces/IQuantumUnlocked.sol";
import "./interfaces/IQuantumKeyRing.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

struct Sale {
    uint128 price;
    uint64 start;
    uint64 limit;
}

struct MPClaim {
    uint64 mpId;
    uint64 start;
    uint128 price;
}

struct Whitelist {
    uint192 price;
    uint64 start;
    bytes32 merkleRoot;
}

struct UnlockedMintAuthorization {
    uint256 id;
    uint256 keyId;
    uint128 dropId;
    uint256 validFrom;
    uint256 validPeriod;
    bytes32 r;
    bytes32 s;
    uint8 v;
}

//TODO: Better drop mechanism
struct UnlockSale {
    uint128 price;
    uint64 start;
    uint64 period;
    address artist;
    uint256 overrideArtistcut;
    uint256[] enabledKeyRanges;
    uint256 numOfVariants;
    uint128 maxDropSupply;
}

struct Auction {
    uint256 startingPrice;
    uint128 decreasingConstant;
    uint64 start;
    uint64 period; //period in seconds : MAX IS 18 HOURS
}

library SalePlatformStorage {
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    struct Layout {
        mapping(uint256 => Auction) auctions;
        mapping(uint256 => Sale) sales;
        mapping(uint256 => MPClaim) mpClaims;
        mapping(uint256 => Whitelist) whitelists;
        uint256 defaultArtistCut; //10000 * percentage
        IQuantumArt quantum;
        IQuantumMintPass mintpass;
        IQuantumUnlocked keyUnlocks;
        IQuantumKeyRing keyRing;
        address[] privilegedContracts;
        BitMapsUpgradeable.BitMap disablingLimiter;
        mapping(uint256 => BitMapsUpgradeable.BitMap) claimedWL;
        mapping(address => BitMapsUpgradeable.BitMap) alreadyBought;
        mapping(uint256 => uint256) overridedArtistCut; // dropId -> cut
        address payable quantumTreasury;
        address authorizer;
        // TODO: Quantum Unlocked appended - needs rewrite
        uint128 nextUnlockDropId;
        mapping(uint256 => mapping(uint256 => bool)) keyUnlockClaims;
        mapping(uint256 => UnlockSale) keySales;
        address blackListAddress;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("quantum.contracts.storage.saleplatform.v1");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

abstract contract SalePlatformAccessors {
    using SalePlatformStorage for SalePlatformStorage.Layout;

    function sales(uint256 dropId) public view returns (Sale memory) {
        return SalePlatformStorage.layout().sales[dropId];
    }

    function mpClaims(uint256 dropId) public view returns (MPClaim memory) {
        return SalePlatformStorage.layout().mpClaims[dropId];
    }

    function whitelists(uint256 dropId) public view returns (Whitelist memory) {
        return SalePlatformStorage.layout().whitelists[dropId];
    }

    function defaultArtistCut() public view returns (uint256) {
        return SalePlatformStorage.layout().defaultArtistCut;
    }

    function privilegedContracts() public view returns (address[] memory) {
        return SalePlatformStorage.layout().privilegedContracts;
    }

    function nextUnlockDropId() public view returns (uint128) {
        return SalePlatformStorage.layout().nextUnlockDropId;
    }

    function keySales(uint256 dropId) public view returns (UnlockSale memory) {
        return SalePlatformStorage.layout().keySales[dropId];
    }
}