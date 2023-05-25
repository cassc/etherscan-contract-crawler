// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ITMAsLocker.sol";
import "../libs/NFT.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TMAsLocker is ITMAsLocker, AccessControl {
    using BitMaps for BitMaps.BitMap;
    using NFT for NFT.TokenStruct;

    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant LOCK_OPERATOR = "LOCK_OPERATOR";

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(LOCK_OPERATOR, ADMIN);
        _grantRole(ADMIN, msg.sender);
    }

    // ==================================================
    // For Lock status
    // ==================================================
    // collectionAddress => lock status
    mapping(address => BitMaps.BitMap) private _isLocked;

    function lock(
        NFT.TokenStruct[] memory tokens
    ) external onlyRole(LOCK_OPERATOR) {
        require(tokens.length > 0, "tokens length must be over 1.");

        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                _isLocked[tokens[i].collectionAddress].get(tokens[i].tokenId) ==
                    false,
                "the token is already locked."
            );
            require(
                IERC721(tokens[i].collectionAddress).ownerOf(
                    tokens[i].tokenId
                ) == tx.origin,
                "you are not holder."
            );
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            _isLocked[tokens[i].collectionAddress].set(tokens[i].tokenId);
        }
    }

    function unlock(
        NFT.TokenStruct[] memory tokens
    ) external onlyRole(LOCK_OPERATOR) {
        require(tokens.length > 0, "tokens length must be over 1.");

        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                IERC721(tokens[i].collectionAddress).ownerOf(
                    tokens[i].tokenId
                ) ==
                    tx.origin ||
                    hasRole(ADMIN, tx.origin),
                "you are not holder."
            );
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            _isLocked[tokens[i].collectionAddress].unset(tokens[i].tokenId);
        }
    }

    function isLocked(
        address collectionAddress,
        uint256 tokenId
    ) external view returns (bool) {
        return _isLocked[collectionAddress].get(tokenId);
    }
}