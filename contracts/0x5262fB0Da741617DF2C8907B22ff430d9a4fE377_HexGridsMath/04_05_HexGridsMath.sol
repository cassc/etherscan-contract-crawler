// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

error BlockIndexOverFlow();
error BlockNotInPass();
error RandomSeedInvalid();

bytes constant initBlockLevels =
    "678851ac687a239ab7ba923c49bcbb995c45accb6b508c4c6897a59cbcba98853ab3bca69c7c6878a967742b4a1";

library HexGridsMath {
    struct Block {
        int256 x;
        int256 y;
        int256 z;
    }

    function PassIdRingNum(uint256 PassId) public pure returns (uint256 n) {
        // PassId = 3 * n * n + 3 * n + 1;
        n = (Math.sqrt(9 + 12 * (PassId - 1)) - 3) / (6);
        if ((3 * n * n + 3 * n + 1) == PassId) {
            return n;
        } else {
            return n + 1;
        }
    }

    function PassIdRingPos(uint256 PassId) public pure returns (uint256) {
        uint256 ringNum = PassIdRingNum(PassId) - 1;
        return PassId - (3 * ringNum * ringNum + 3 * ringNum + 1);
    }

    function PassIdRingStartCenterPoint(uint256 PassIdRingNum_) public pure returns (Block memory) {
        int256 PassIdRingNum__ = int256(PassIdRingNum_);
        return Block(-PassIdRingNum__ * 5, PassIdRingNum__ * 11, -PassIdRingNum__ * 6);
    }

    function PassIdCenterPoint(uint256 PassId) public pure returns (Block memory block_) {
        if (PassId == 1) {
            return block_;
        }

        uint256 PassIdRingNum_ = PassIdRingNum(PassId);
        int256 PassIdRingNum__ = int256(PassIdRingNum_);
        Block memory startblock = PassIdRingStartCenterPoint(PassIdRingNum_);
        uint256 PassIdRingPos_ = PassIdRingPos(PassId);
        int256 PassIdRingPos__ = int256(PassIdRingPos_) - 1;

        uint256 side = Math.ceilDiv(PassIdRingPos_, PassIdRingNum_);
        int256 sidepos = 0;
        if (PassIdRingNum__ > 1) {
            sidepos = PassIdRingPos__ % PassIdRingNum__;
        }

        if (side == 1) {
            block_.x = startblock.x + sidepos * 11;
            block_.y = startblock.y - sidepos * 6;
            block_.z = startblock.z - sidepos * 5;
        } else if (side == 2) {
            block_.x = -startblock.z + sidepos * 5;
            block_.y = -startblock.x - sidepos * 11;
            block_.z = -startblock.y + sidepos * 6;
        } else if (side == 3) {
            block_.x = startblock.y - sidepos * 6;
            block_.y = startblock.z - sidepos * 5;
            block_.z = startblock.x + sidepos * 11;
        } else if (side == 4) {
            block_.x = -startblock.x - sidepos * 11;
            block_.y = -startblock.y + sidepos * 6;
            block_.z = -startblock.z + sidepos * 5;
        } else if (side == 5) {
            block_.x = startblock.z - sidepos * 5;
            block_.y = startblock.x + sidepos * 11;
            block_.z = startblock.y - sidepos * 6;
        } else if (side == 6) {
            block_.x = -startblock.y + sidepos * 6;
            block_.y = -startblock.z + sidepos * 5;
            block_.z = -startblock.x - sidepos * 11;
        }
    }

    function PassIdCenterPointRange(Block memory block_)
        public
        pure
        returns (int256[] memory, int256[] memory, int256[] memory)
    {
        int256[] memory xrange = new int256[](11);
        int256[] memory yrange = new int256[](11);
        int256[] memory zrange = new int256[](11);
        for (uint256 i = 1; i < 6; i++) {
            xrange[i * 2] = block_.x + int256(i);
            xrange[i * 2 - 1] = block_.x - int256(i);
            yrange[i * 2] = block_.y + int256(i);
            yrange[i * 2 - 1] = block_.y - int256(i);
            zrange[i * 2] = block_.z + int256(i);
            zrange[i * 2 - 1] = block_.z - int256(i);
        }
        xrange[0] = block_.x;
        yrange[0] = block_.y;
        zrange[0] = block_.z;
        return (xrange, yrange, zrange);
    }

    function blockIndex(Block memory block_, uint256 PassId) public pure returns (int256 blockIndex_) {
        Block memory centerPointBlock = PassIdCenterPoint(PassId);
        int256 dis = block_distance(centerPointBlock, block_);
        if (dis > 5) revert BlockNotInPass();
        dis--;
        blockIndex_ = 3 * dis * dis + 3 * dis;
        dis++;
        block_ = block_subtract(block_, centerPointBlock);
        if (block_.x >= 0 && block_.y > 0 && block_.z < 0) {
            blockIndex_ += block_distance(Block(0, dis, -dis), block_) + 1;
        } else if (block_.x > 0 && block_.y <= 0 && block_.z < 0) {
            blockIndex_ += block_distance(Block(dis, 0, -dis), block_) + 1 + dis;
        } else if (block_.x > 0 && block_.y < 0 && block_.z >= 0) {
            blockIndex_ += block_distance(Block(dis, -dis, 0), block_) + 1 + dis * 2;
        } else if (block_.x <= 0 && block_.y < 0 && block_.z > 0) {
            blockIndex_ += block_distance(Block(0, -dis, dis), block_) + 1 + dis * 3;
        } else if (block_.x < 0 && block_.y >= 0 && block_.z > 0) {
            blockIndex_ += block_distance(Block(-dis, 0, dis), block_) + 1 + dis * 4;
        } else {
            blockIndex_ += block_distance(Block(-dis, dis, 0), block_) + 1 + dis * 5;
        }
    }

    function blockLevels(bytes32 randomseed) public pure returns (uint8[] memory) {
        if (randomseed.length < 10) {
            revert RandomSeedInvalid();
        }
        unchecked {
            uint8[] memory blockLevels_ = new uint8[](91);
            uint256 startIndex = uint256(uint8(randomseed[0])) % 91;
            uint256 k = 0;
            uint256 index;
            for (uint256 i = 0; i < 9; i++) {
                uint256 groupIndex = uint256(uint8(randomseed[i + 1])) % 10;

                for (uint256 j = 0; j < 10; j++) {
                    index = (startIndex + (i * 10) + (groupIndex + j) % 10) % 91;
                    blockLevels_[k] = convertBytes1level(initBlockLevels[index]);
                    k++;
                }
            }
            if (startIndex == 0) {
                blockLevels_[k] = convertBytes1level(initBlockLevels[k]);
            } else {
                blockLevels_[k] = convertBytes1level(initBlockLevels[startIndex - 1]);
            }
            return blockLevels_;
        }
    }

    function blockLevel(bytes32 randomseed, uint256 blockIndex_) public pure returns (uint8) {
        if (randomseed.length < 10) {
            revert RandomSeedInvalid();
        }
        if (blockIndex_ > 90) {
            revert BlockIndexOverFlow();
        }
        unchecked {
            uint256 startIndex = uint256(uint8(randomseed[0])) % 91;
            if (blockIndex_ == 90) {
                if (startIndex == 0) {
                    return convertBytes1level(initBlockLevels[blockIndex_]);
                }
                return convertBytes1level(initBlockLevels[startIndex - 1]);
            }
            uint256 i = blockIndex_ / 10;
            uint256 groupIndex = uint256(uint8(randomseed[i])) % 10;
            uint256 index = (startIndex + i * 10 + (groupIndex + (blockIndex_ % 10)) % 10) % 91;
            return convertBytes1level(initBlockLevels[index]);
        }
    }

    function convertBytes1level(bytes1 level) public pure returns (uint8) {
        uint8 uint8level = uint8(level);
        if (uint8level < 97) {
            return uint8level - 48;
        } else {
            return uint8level - 87;
        }
    }

    function block_add(Block memory a, Block memory b) public pure returns (Block memory) {
        return Block(a.x + b.x, a.y + b.y, a.z + b.z);
    }

    function block_subtract(Block memory a, Block memory b) public pure returns (Block memory) {
        return Block(a.x - b.x, a.y - b.y, a.z - b.z);
    }

    function block_length(Block memory a) public pure returns (int256) {
        return int256((SignedMath.abs(a.x) + SignedMath.abs(a.y) + SignedMath.abs(a.z)) / 2);
    }

    function block_distance(Block memory a, Block memory b) public pure returns (int256) {
        return block_length(block_subtract(a, b));
    }

    function block_direction(uint256 direction) public pure returns (Block memory) {
        Block[] memory cube_direction_vectors = new Block[](6);
        cube_direction_vectors[0] = Block(1, 0, -1);
        cube_direction_vectors[1] = Block(1, -1, 0);
        cube_direction_vectors[2] = Block(0, -1, 1);
        cube_direction_vectors[3] = Block(-1, 0, 1);
        cube_direction_vectors[4] = Block(-1, 1, 0);
        cube_direction_vectors[5] = Block(0, 1, -1);
        return cube_direction_vectors[direction];
    }

    function block_neighbor(Block memory block_, uint256 direction) public pure returns (Block memory) {
        return block_add(block_, block_direction(direction));
    }
}