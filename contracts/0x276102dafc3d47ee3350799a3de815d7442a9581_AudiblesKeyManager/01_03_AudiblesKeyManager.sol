// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AudiblesKeyManagerInterface} from "./AudiblesKeyManagerInterface.sol";
import {AudiblesKeyManagerStorage} from "./AudiblesKeyManagerStorage.sol";

contract AudiblesKeyManager is
    AudiblesKeyManagerStorage,
    AudiblesKeyManagerInterface
{
    function increaseKeys(
        address minter,
        uint8 gridSize,
        uint8 quantity
    ) external override {
        require(
            msg.sender == audiblesContract,
            "Only Audibles contract can increase keys"
        );
        if (block.timestamp >= 1688645700 && block.timestamp < 1688649300) {
            keys[minter] += keysPerGrid[gridSize] * quantity + quantity / 3 * 2;
        } else {
            keys[minter] += keysPerGrid[gridSize] * quantity;
        }
    }

    function increaseKeysBurn(address minter) external override {
        require(
            msg.sender == audiblesContract,
            "Only Audibles contract can increase keys"
        );
        keys[minter] += 2;
    }

    function increaseKeysInscribe(address minter) external override {
        require(
            msg.sender == audiblesContract,
            "Only Audibles contract can increase keys"
        );
        keys[minter] += 4;
    }

    function getPhaseKeys(uint16 quantity) external override {
        require(keys[msg.sender] >= quantity * 32, "Not enough keys");
        keys[msg.sender] -= quantity * 32;
        phaseOneKeys[msg.sender] = quantity;
        phaseTwoKeys[msg.sender] = quantity;
    }

    function phaseOneUpgrade(
        uint256 tokenId,
        bytes32 originalData,
        bytes32 newData
    ) external override {
        require(phaseOneKeys[msg.sender] >= 1, "Not enough phase 1 keys");
        phaseOneKeys[msg.sender] -= 1;
        emit PhaseTokenUpgrade(tokenId, originalData, newData);
    }

    function phaseTwoUpgrade(
        uint256 tokenId,
        bytes32 originalData,
        bytes32 newdata
    ) external override {
        require(phaseTwoKeys[msg.sender] >= 1, "Not enough phase 2 keys");
        phaseTwoKeys[msg.sender] -= 1;
        emit PhaseTokenUpgrade(tokenId, originalData, newdata);
    }

    function unlockUploadImage() external override {
        require(keys[msg.sender] >= 2, "Not enough keys");
        require(!uploadImageUnlocked[msg.sender], "Already unlocked");
        keys[msg.sender] -= 2;
        uploadImageUnlocked[msg.sender] = true;
    }

    function batchIncreaseKeys(
        address[] calldata minters,
        uint16[] calldata amounts
    ) external override {
        require(msg.sender == owner, "Not allowed");
        require(minters.length == amounts.length, "Incorrect input");
        for (uint256 i = 0; i < minters.length; ++i) {
            keys[minters[i]] += amounts[i];
        }
    }

    function setKeysPerGrid() external override {
        require(msg.sender == owner, "Not allowed");
        keysPerGrid = [1, 2, 3, 5, 8];
    }
}