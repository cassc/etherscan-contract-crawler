// SPDX-License-Identifier: GPL-3.0

/// @title The MojosToken pseudo-random seed generator

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░███████████████████████░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 * ░░░░░░█████████████████░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { IMojosSeeder } from './interfaces/IMojosSeeder.sol';
import { IMojosDescriptor } from './interfaces/IMojosDescriptor.sol';

contract MojosSeeder is IMojosSeeder {
    /**
     * @notice Generate a pseudo-random Mojo seed using the previous blockhash and Mojo ID.
     */
    // prettier-ignore
    function generateSeed(uint256 mojoId, IMojosDescriptor descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), mojoId))
        );

        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 bodyCount = descriptor.bodyCount();
        uint256 bodyAccessoryCount = descriptor.bodyAccessoryCount();
        uint256 faceCount  = descriptor.faceCount();
        uint256 headAccessoryCount  = descriptor.headAccessoryCount();

        return Seed({
        background: uint48(
                uint48(pseudorandomness) % backgroundCount
            ),
        body: uint48(
                uint48(pseudorandomness >> 48) % bodyCount
            ),
        bodyAccessory: uint48(
                uint48(pseudorandomness >> 96) % bodyAccessoryCount
            ),
        face: uint48(
                uint48(pseudorandomness >> 144) % faceCount
            ),
        headAccessory: uint48(
                uint48(pseudorandomness >> 192) % headAccessoryCount
            )
        });
    }
}