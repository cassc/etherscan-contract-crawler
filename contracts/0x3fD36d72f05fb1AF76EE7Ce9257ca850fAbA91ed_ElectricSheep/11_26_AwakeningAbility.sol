// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract AwakeningAbility is Ownable, ERC721 {
    error TokenAwakening();
    error AwakeningLocked();
    error CallerNotOwner();
    error CallerNotOwnerNorApproved();

    event AwakeningLockUpdated(bool unlocked);
    event AwakeningStarted(uint256 indexed tokenId, address indexed owner);
    event AwakeningStopped(uint256 indexed tokenId, address indexed owner);
    event AwakeningInterrupted(uint256 indexed tokenId, address indexed owner);
    event AwakeningTransfer(address indexed from, address indexed to, uint256 indexed tokenId);

    bool public isAwakeningUnlocked;
    bool private isAwakeningTransferAllowed;
    mapping(uint256 => bool) public awakeningState;

    /**
     * @notice Unlock the awakening abilitiy
     * @param unlocked unlock flag
     */
    function unlockAwakening(bool unlocked) external onlyOwner {
        isAwakeningUnlocked = unlocked;
        emit AwakeningLockUpdated(unlocked);
    }

    /**
     * @notice Interrupt the awakening state of token which was deliberately placed at a low price on marketplace but can't be traded
     * @param tokenIds list of tokenId
     */
    function interruptAwakening(uint256[] calldata tokenIds) external onlyOwner {
        uint256 size = tokenIds.length;
        for (uint256 i = 0; i < size; i++) {
            uint256 tokenId = tokenIds[i];
            if (awakeningState[tokenId]) {
                awakeningState[tokenId] = false;
                address owner = ownerOf(tokenId);
                emit AwakeningStopped(tokenId, owner);
                emit AwakeningInterrupted(tokenId, owner);
            }
        }
    }

    /**
     * @notice Set tokens' awakening state
     * @param tokenIds list of tokenId
     */
    function setAwakeningState(uint256[] calldata tokenIds, bool state) external {
        uint256 size = tokenIds.length;
        for (uint256 i = 0; i < size; i++) {
            uint256 tokenId = tokenIds[i];
            if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
                revert CallerNotOwnerNorApproved();
            }
            bool currentState = awakeningState[tokenId];
            if (currentState && !state) {
                awakeningState[tokenId] = false;
                emit AwakeningStopped(tokenId, ownerOf(tokenId));
            } else if (!currentState && state) {
                if (!isAwakeningUnlocked) {
                    revert AwakeningLocked();
                }
                awakeningState[tokenId] = true;
                emit AwakeningStarted(tokenId, ownerOf(tokenId));
            }
        }
    }

    /**
     * @notice Transfer token while it is awakening
     * @param from transfer from address
     * @param to transfer to address
     * @param tokenId token must be owned by `from`
     */
    function safeTransferWhileAwakening(address from, address to, uint256 tokenId) public {
        if (ownerOf(tokenId) != _msgSender()) {
            revert CallerNotOwner();
        }
        isAwakeningTransferAllowed = true;
        safeTransferFrom(from, to, tokenId);
        isAwakeningTransferAllowed = false;
        if (awakeningState[tokenId]) {
            emit AwakeningTransfer(from, to, tokenId);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        if (awakeningState[tokenId] && !isAwakeningTransferAllowed) {
            revert TokenAwakening();
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
}