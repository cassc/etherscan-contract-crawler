// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import { ISweepersSeeder } from './interfaces/ISweepersSeeder.sol';
import { ISweepersDescriptor } from './interfaces/ISweepersDescriptor.sol';

contract SweepersSeeder is ISweepersSeeder {
    /**
     * @notice Generate a pseudo-random Sweeper seed using the previous blockhash and sweeper ID.
     */
    // prettier-ignore
    function generateSeed(uint256 sweeperId, ISweepersDescriptor descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), sweeperId))
        );

        uint256 bodyCount = descriptor.bodyCount();
        uint256 accessoryCount = descriptor.accessoryCount();
        uint256 headCount = descriptor.headCount();
        uint256 eyesCount = descriptor.eyesCount();
        uint256 mouthCount = descriptor.mouthCount();

        uint48 backgroundRandomness = uint48(pseudorandomness) % 400;
        uint48 randomBackground;

        if(backgroundRandomness == 0) {
            randomBackground = 3;
        } else if(backgroundRandomness <= 2) {
            randomBackground = 11;
        } else if(backgroundRandomness <= 6) {
            randomBackground = 4;
        } else if(backgroundRandomness <= 18) {
            randomBackground = 0;
        } else if(backgroundRandomness <= 56) {
            randomBackground = 2;
        } else if(backgroundRandomness <= 94) {
            randomBackground = 5;
        } else if(backgroundRandomness <= 132) {
            randomBackground = 6;
        } else if(backgroundRandomness <= 170) {
            randomBackground = 7;
        } else if(backgroundRandomness <= 208) {
            randomBackground = 8;
        } else if(backgroundRandomness <= 246) {
            randomBackground = 9;
        } else if(backgroundRandomness <= 284) {
            randomBackground = 10;
        } else if(backgroundRandomness <= 322) {
            randomBackground = 1;
        } else if(backgroundRandomness <= 360) {
            randomBackground = 12;
        } else {
            randomBackground = 13;
        }

        return Seed({
            background: randomBackground,
            body: uint48(
                uint48(pseudorandomness >> 48) % bodyCount
            ),
            accessory: uint48(
                uint48(pseudorandomness >> 96) % accessoryCount
            ),
            head: uint48(
                uint48(pseudorandomness >> 144) % headCount
            ),
            eyes: uint48(
                uint48(pseudorandomness >> 192) % eyesCount
            ),
            mouth: uint48(
                uint48(pseudorandomness >> 208) % mouthCount
            )
        });
    }
}