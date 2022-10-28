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
            randomBackground = 14;
        } else if(backgroundRandomness <= 18) {
            randomBackground = 0;
        } else if(backgroundRandomness <= 58) {
            randomBackground = 16;
        } else if(backgroundRandomness <= 138) {
            randomBackground = 15;
        } else if(backgroundRandomness <= 164) {
            randomBackground = 2;
        } else if(backgroundRandomness <= 190) {
            randomBackground = 5;
        } else if(backgroundRandomness <= 216) {
            randomBackground = 6;
        } else if(backgroundRandomness <= 242) {
            randomBackground = 7;
        } else if(backgroundRandomness <= 268) {
            randomBackground = 8;
        } else if(backgroundRandomness <= 294) {
            randomBackground = 9;
        } else if(backgroundRandomness <= 320) {
            randomBackground = 10;
        } else if(backgroundRandomness <= 346) {
            randomBackground = 1;
        } else if(backgroundRandomness <= 372) {
            randomBackground = 12;
        } else {
            randomBackground = 17;
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