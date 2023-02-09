// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../preclude/Preclude.sol";

import "../ownable/OwnableLayout.sol";
import "../nameServiceRef/NameServiceRefLayout.sol";
import "../reentrancy/ReentrancyLayout.sol";
import "../erc721/HERC721Layout.sol";

abstract contract HERC721IMLayout is OwnableLayout, NameServiceRefLayout, ReentrancyLayout, HERC721Layout {

    using Counters for Counters.Counter;

    bool internal _supportTransfer;
    bool internal _supportMint;
    bool internal _sudoMint;
    bool internal _supportBurn;
    bool internal _sudoBurn;

    //statistic
    uint256 internal _transferTxs;
    EnumerableSet.AddressSet internal _interactAccounts;

    //local block and privilege list
    mapping(address => bool) internal _blockListFrom;
    mapping(address => bool) internal _blockListTo;
    mapping(address => bool) internal _privilegeListFrom;
    mapping(address => bool) internal _privilegeListTo;

    //A.I.
    Counters.Counter internal _tokenIdCounter;

    uint256 internal _tokenIdMapRangeBegin;
    uint256 internal _tokenIdMapRangeEnd;

    //tokenId -> lockCount
    mapping(uint256 => uint256) internal _tokenLocks;
    //tokenId -> unlocker -> lock count
    mapping(uint256 => mapping(address => uint256)) internal _tokenLockCounts;

    //attributeName -> tokenId -> data
    mapping(bytes32 => mapping(uint256 => bytes32)) internal _fixedAttribute;
    mapping(bytes32 => mapping(uint256 => bytes)) internal _dynamicAttribute;

    EnumerableSet.Bytes32Set internal _attributeNames;
    //name => type
    mapping(bytes32 => uint256) _attributeType;
}