// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../Locker/ITMAsLocker.sol";
import "../libs/NFT.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract TMAsProtector is AccessControl {
    using BitMaps for BitMaps.BitMap;
    using EnumerableSet for EnumerableSet.AddressSet;
    using NFT for NFT.TokenStruct;

    bytes32 public constant ADMIN = "ADMIN";

    ITMAsLocker public locker;
    EnumerableSet.AddressSet private _allowedCollections;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);
        _grantRole(ADMIN, msg.sender);
    }

    /**  @dev ステーキング中のトークンをProtectorからアンロックしてしまわないようにここでも状態管理する */
    // collectionAddress => lock status
    mapping(address => BitMaps.BitMap) private _isLocked;

    function lock(NFT.TokenStruct[] memory tokens) external {
        require(tokens.length > 0, "tokens length must be over 1.");

        locker.lock(tokens);

        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                _allowedCollections.contains(tokens[i].collectionAddress),
                "no supported collection."
            );
            _isLocked[tokens[i].collectionAddress].set(tokens[i].tokenId);
        }
    }

    function unlock(NFT.TokenStruct[] memory tokens) external {
        // Assuming that the Locker guarantees that only the holder or ADMIN can operate it.
        require(tokens.length > 0, "tokens length must be over 1.");

        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                _isLocked[tokens[i].collectionAddress].get(tokens[i].tokenId) ==
                    true,
                "the token is not protected."
            );
        }

        locker.unlock(tokens);
    }

    function isProtected(
        address collectionAddress,
        uint256 tokenId
    ) external view returns (bool) {
        return _isLocked[collectionAddress].get(tokenId);
    }

    function setLocker(address value) external onlyRole(ADMIN) {
        locker = ITMAsLocker(value);
    }

    function addAllowedCollection(
        address[] calldata addresses
    ) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowedCollections.add(addresses[i]);
        }
    }

    function removeAllowedCollection(
        address[] calldata addresses
    ) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowedCollections.remove(addresses[i]);
        }
    }

    function getAllowedCollection() external view returns (address[] memory) {
        return _allowedCollections.values();
    }
}