// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { ISweepersSeeder } from './interfaces/ISweepersSeeder.sol';
import { ISweepersDescriptor } from './interfaces/ISweepersDescriptor.sol';

contract SweepersSeeder is ISweepersSeeder {

    uint256 public pantryStart = 1673913600;

    function setSpecialTimes(uint256 _pantryStart) external {
        require(msg.sender == 0x9D0717fAdDb61c48e3fCE46ABC2B2DCAA43D1255);
        pantryStart = _pantryStart;
    }
    
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

        if(block.timestamp < pantryStart) {
            if(backgroundRandomness == 0) {
                randomBackground = 3;
            } else if(backgroundRandomness <= 2) {
                randomBackground = 11;
            } else if(backgroundRandomness <= 6) {
                randomBackground = 14;
            } else if(backgroundRandomness <= 18) {
                randomBackground = 21;
            } else if(backgroundRandomness <= 98) {
                randomBackground = 24;
            } else if(backgroundRandomness <= 128) {
                randomBackground = 2;
            } else if(backgroundRandomness <= 158) {
                randomBackground = 5;
            } else if(backgroundRandomness <= 189) {
                randomBackground = 6;
            } else if(backgroundRandomness <= 229) {
                randomBackground = 7;
            } else if(backgroundRandomness <= 259) {
                randomBackground = 8;
            } else if(backgroundRandomness <= 289) {
                randomBackground = 9;
            } else if(backgroundRandomness <= 319) {
                randomBackground = 10;
            } else if(backgroundRandomness <= 349) {
                randomBackground = 1;
            } else if(backgroundRandomness <= 379) {
                randomBackground = 12;
            } else {
                randomBackground = 17;
            }
        } else {
           if(backgroundRandomness == 0) {
                randomBackground = 3;
            } else if(backgroundRandomness <= 2) {
                randomBackground = 11;
            } else if(backgroundRandomness <= 6) {
                randomBackground = 25;
            } else if(backgroundRandomness <= 18) {
                randomBackground = 21;
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
            } else if(backgroundRandomness <= 285) {
                randomBackground = 10;
            } else if(backgroundRandomness <= 323) {
                randomBackground = 1;
            } else if(backgroundRandomness <= 361) {
                randomBackground = 12;
            } else {
                randomBackground = 17;
            }
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