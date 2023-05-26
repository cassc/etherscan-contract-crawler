// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Random.sol";

library GenesLib {
    using SafeMath for uint;
    uint private constant MAGIC_NUM = 0x123456789ABCDEF;

    struct GenesRange {
        uint from;
        uint to;
    }

    function setGeneLevelTo(uint genes, uint level, uint position) internal pure returns (uint) {
        return genes | uint(level << (position * 4));
    }

    function geneLevelAt(uint genes, uint position) internal pure returns (uint) {
        return (genes >> (position * 4)) & 0xF;
    }

    function zeroGenePositionsInRange(uint genes, GenesRange memory range) 
    internal pure returns (uint, uint[] memory) {
        uint[] memory zeroPositions = new uint[](range.to - range.from);
        uint count = 0;
        for (uint pos = range.from; pos < range.to; pos++) {
            uint level = geneLevelAt(genes, pos);
            if (level == 0) {
                zeroPositions[count] = pos;
                count++;
            }
        }
        return (count, zeroPositions);
    }

    function randomGeneLevel(uint randomValue, bool includeZero) internal pure returns (uint) {
        if (includeZero) {
            return randomValue.mod(16);
        }
        else {
            return 1 + randomValue.mod(15);
        }
    }

    function randomInheritGenesInRange(uint genes, uint parent1Genes, uint parent2Genes,
        GenesRange memory range, uint randomValue, bool includeZero) internal pure returns (uint) {
        
        for (uint pos = range.from; pos < range.to; pos++) {
            uint geneLevel1 = geneLevelAt(parent1Genes, pos);
            uint geneLevel2 = geneLevelAt(parent2Genes, pos);

            if (includeZero || (geneLevel1 > 0 && geneLevel2 > 0)) {
                uint d = (pos % 2 == 0) ? ((randomValue >> pos) + (MAGIC_NUM >> pos)) : ~(randomValue >> pos);
                uint r = d.mod(100);
                
                if (r < 45) { //45%
                    genes = setGeneLevelTo(genes, geneLevel1, pos);
                }
                else if (r >= 45 && r < 90) { //45%
                    genes = setGeneLevelTo(genes, geneLevel2, pos);
                }
                else { //10%
                    uint level = randomGeneLevel(d, includeZero);
                    genes = setGeneLevelTo(genes, level, pos);
                }
            }
        }
        return genes;
    }

    function randomSetGenesToPositions(uint genes, uint[] memory positions, uint randomValue, bool includeZero) 
    internal pure returns (uint) {
        for (uint i = 0; i < positions.length; i++) {
            genes = setGeneLevelTo(genes, randomGeneLevel(
                (i % 2 > 0) ? ((randomValue >> i) + (MAGIC_NUM >> i)) : ~(randomValue >> i), 
                includeZero), positions[i]);
        }
        return genes;
    }

    function randomGenePositions(GenesRange memory range, uint count, uint randomValue) 
    internal pure returns (uint[] memory) {
        if (count > 0) {
            uint[] memory shuffledRangeArray = 
                Random.shuffle(createOrderedRangeArray(range.from, range.to), randomValue);
            uint[] memory positions = new uint[](count);
            for (uint i = 0; i < count; i++) {
                positions[i] = shuffledRangeArray[i];
            }
            return positions;
        }
        return new uint[](0);
    }

    function createOrderedRangeArray(uint from, uint to) internal pure returns (uint[] memory) {
        uint[] memory rangeArray = new uint[](to - from) ;
        for (uint i = 0; i < rangeArray.length; i++) {
            rangeArray[i] = from + i;
        }
        return rangeArray;
    }

}