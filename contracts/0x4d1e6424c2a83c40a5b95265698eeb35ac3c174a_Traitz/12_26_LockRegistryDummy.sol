// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC721xDummy.sol";

abstract contract LockRegistryDummy is OwnableUpgradeable, IERC721xDummy {
    mapping(address => bool) approvedContract;
    mapping(uint256 => uint256) lockCount;
    mapping(uint256 => mapping(uint256 => address)) lockMap;
    mapping(uint256 => mapping(address => uint256)) lockMapIndex;

    function __LockRegistry_init() internal onlyInitializing {
        OwnableUpgradeable.__Ownable_init();
    }
}