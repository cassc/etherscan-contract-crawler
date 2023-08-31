// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2023, GSKNNFT Inc
pragma solidity ^0.8.20;

import {CountersUpgradeable} from "@gnus.ai/contracts-upgradeable-diamond/contracts/utils/CountersUpgradeable.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LibDiamond} from "./LibDiamond.sol";

library LibDiamondDapes {
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using LibDiamond for LibDiamond.DiamondStorage;
  bytes32 constant DIAMOND_DAPES_STORAGE_POSITION = keccak256("diamonddapes.standard.diamond.dapes.storage");
  bytes32 constant EXTRAAF_STORAGE_POSITION = keccak256("extraaf.standard.apefathers.storage");
  bytes32 constant AFADMIN_STORAGE_POSITION = keccak256("diamonddapes.standard.apefathers.storage");
  bytes32 constant STAGED_INIT_STORAGE_POSITION = keccak256("diamonddapes.stagedinit.standard.diamond.storage");
  uint256 constant MAX_SUPPLY = 4000;

  struct DiamondDapesStruct {
    // AdminFacet state variables
    // Mapping from token ID to metadata URI
    uint8 batchSizePerTx; // Number of tokens to mint per batch
    uint8 attributes;
    uint16 apeIndex;
    uint16 mintedCount;
    uint64 generation;
    uint96 royaltyFee;
    uint96 tokenCount;
    bool admininitialized;
    bool isActive;
    bool isTokenBurnActive;
    bool isPaused;
    bool isSpecial;
    bool isPublicSaleActive;
    bool isBurnClaimActive;
    bool isBatchMintActive;
    bool metadataFrozen; // Permanently freezes metadata so it can never be changed
    bool payoutAddressesFrozen; // If true, payout addresses and basis points are permanently frozen and can never be updated
    bool revealed;
    bool holderRoyaltiesActive;
    bool collectionRevealed;
    bool[50] __gapBool;
    uint256 _tokenIds;
    uint256 _totalSupply;
    uint256 publicPrice;
    uint256 tokensPerBatch; // Number of tokens to reveal per batch
    uint256 totalRevealed; // Keep track of total number of tokens already revealed
    uint256 holderPercents;
    uint256 publicCloseTokenId;
    uint16[] payoutBasisPoints; // The respective share of funds to be sent to each address in payoutAddresses in basis points
    uint256[50] __gapUint256;
    string baseURI;
    string fullURI;
    string hiddenMetadataUri;
    string name;
    string symbol;
    string uriPrefix;
    string uriSuffix;
    string version;
    bytes32 facetId;
    string[50] __gapString;
    address[] diamondDependencies;
    address[] payoutAddresses;
    address[50] __gapAddress;
    address nftAddress;
    address payable diamondAddress;
    address libAddress;
    address royaltyAddress;
    address tokenOwner;
  }

  struct AdminStorage {
    uint256 nonce;
    mapping(uint256 => bool) revealedTokens;
    // Supported interfaces
    mapping(bytes4 => bool) _supportedInterfaces;
    // Allowed facets
    mapping(address => bool) allowedFacets;
    // Admin addresses
    address[] admins;
    // Balances
    mapping(address => uint256) balances;
    // Token ownership
    mapping(uint256 => address) _owners;
    // Token approvals
    mapping(uint256 => mapping(address => bool)) tokenApprovals;
    // Extra NFT data storage
    mapping(uint256 => string[]) _tokenIPFSHashes;
    // Token URIs
    mapping(uint256 => string) _tokenURIs;
    // Owned token IDs
    mapping(address => uint256[]) _ownedTokens;
    // Index of owned token IDs
    mapping(uint256 => uint256) _ownedTokensIndex;
    // Proxy mapping for projects
    mapping(address => bool) projectProxy;
    // Proxy mapping
    mapping(address => bool) proxyAddress;
  }

  struct ExtraStorage {
    // Counters
    CountersUpgradeable.Counter _tokenIdTracker;
    CountersUpgradeable.Counter _supplyTracker;
  }

  struct StagedInit {
    bool stage1Initialized;
    bool diamondInitialized;
    bool adminInitialized;
    bool royaltiesInitialized;
    bool approvalsInitialized;
  }

  bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
  bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));
  bytes32 constant CLEAR_SELECTOR = CLEAR_ADDRESS_MASK | CLEAR_SELECTOR_MASK;
  bytes32 constant SELECTOR_SIZE = bytes32(uint256(0xffffffff << 224));
  bytes32 constant SELECTOR_SHIFT =
    bytes32(uint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) << 224);
  bytes32 constant SELECTOR_MASK = CLEAR_ADDRESS_MASK | SELECTOR_SIZE;
  bytes32 constant SELECTOR_OFFSET = bytes32(uint256(0xffffffff << 224) >> 1);
  bytes32 constant DIAMOND_STORAGE_OFFSET = bytes32(uint256(0xffffffff << 224) >> 2);
  bytes32 constant DIAMOND_STORAGE_SIZE = bytes32(uint256(0xffffffff << 224) >> 3);
  bytes32 constant DIAMOND_STORAGE_MASK = CLEAR_ADDRESS_MASK | DIAMOND_STORAGE_SIZE;
  bytes32 constant DIAMOND_STORAGE_SHIFT =
    bytes32(uint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) << 224) >> 4;
  bytes32 constant DIAMOND_STORAGE = DIAMOND_STORAGE_OFFSET | DIAMOND_STORAGE_SIZE;

  function extraStorage() internal pure returns (ExtraStorage storage ex) {
    bytes32 position = EXTRAAF_STORAGE_POSITION;
    assembly {
      ex.slot := position
    }
  }

  function diamondDapesStorage() internal pure returns (DiamondDapesStruct storage dds) {
    bytes32 position = DIAMOND_DAPES_STORAGE_POSITION;
    assembly {
      dds.slot := position
    }
  }

  function adminStorage() internal pure returns (AdminStorage storage aStore) {
    bytes32 position = AFADMIN_STORAGE_POSITION;
    assembly {
      aStore.slot := position
    }
  }

  /*
    function enforceIsAdmin() internal view returns (AdminStorage storage aStore) {
        require(msg.sender == adminStorage().admin, "Must be admin");
    }
*/
  function stagedInitStorage() internal pure returns (StagedInit storage sInit) {
    bytes32 position = STAGED_INIT_STORAGE_POSITION;
    assembly {
      sInit.slot := position
    }
  }

  function setAddress(address _address) internal {
    DiamondDapesStruct storage diamondDapesStruct = diamondDapesStorage();
    diamondDapesStruct.libAddress = _address;
  }

  function getAddress() internal view returns (address) {
    DiamondDapesStruct storage diamondDapesStruct = diamondDapesStorage();
    return diamondDapesStruct.libAddress;
  }

  // Function to set a proxy address
  function setProxy(address _proxyAddress) internal {
    LibDiamond.enforceIsContractOwner();
    adminStorage().proxyAddress[_proxyAddress] = true;
  }

  // Function to remove a proxy address
  function removeProxy(address _proxyAddress) internal {
    LibDiamond.enforceIsContractOwner();
    delete adminStorage().proxyAddress[_proxyAddress];
  }

  // Function to activate a proxy
  function activateProxy(address _proxyAddress) internal {
    require(adminStorage().proxyAddress[_proxyAddress], "Proxy address not found");
    adminStorage().proxyAddress[_proxyAddress] = true;
  }

  // Function to deactivate a proxy
  function deactivateProxy(address _proxyAddress) internal {
    require(adminStorage().proxyAddress[_proxyAddress], "Proxy address not found");
    adminStorage().proxyAddress[_proxyAddress] = false;
  }
}