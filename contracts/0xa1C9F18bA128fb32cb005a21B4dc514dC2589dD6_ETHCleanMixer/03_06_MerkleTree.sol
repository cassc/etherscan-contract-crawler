//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface Hasher {
    function MiMCSponge(
        uint256 xL_in,
        uint256 xR_in,
        uint256 k
    ) external pure returns (uint256 xL, uint256 xR);
}

contract MerkleTree {
    uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 public constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("tornado") % FIELD_SIZE

    uint32 public levels;
    Hasher public hasher;

    // for insert calculation
    bytes32[] public zeros;
    bytes32[] public filledSubtrees;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;
    uint32 public constant ROOT_HISTORY_SIZE = 100;
    bytes32[ROOT_HISTORY_SIZE] public roots;

    constructor(uint32 _levels, Hasher _hasher) {
        require(_levels > 0, "_level should be greater than zero");
        require(_levels < 32, "_level should be less than 32");
        levels = _levels;
        hasher = _hasher;

        // fill zeros and filledSubtrees depend on levels
        bytes32 currentZero = bytes32(ZERO_VALUE);
        zeros.push(currentZero);
        filledSubtrees.push(currentZero);
        for (uint32 i = 1; i < levels; i++) {
            currentZero = hashLeftRight(currentZero, currentZero);
            zeros.push(currentZero);
            filledSubtrees.push(currentZero);
        }

        roots[0] = hashLeftRight(currentZero, currentZero);
    }

    function hashLeftRight(bytes32 _left, bytes32 _right) public view returns (bytes32) {
        require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
        require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
        uint256 R = uint256(_left);
        uint256 C = 0;
        uint256 k = 0;
        (R, C) = hasher.MiMCSponge(R, C, k);
        R = addmod(R, uint256(_right), FIELD_SIZE);
        (R, C) = hasher.MiMCSponge(R, C, k);
        return bytes32(R);
    }

    function _insert(bytes32 _leaf) internal returns (uint32 index) {
        uint32 currentIndex = nextIndex;
        require(currentIndex < uint32(2)**levels, "Merkle tree is full. No more leaf can be added");
        nextIndex += 1;
        bytes32 currentLevelHash = _leaf;
        bytes32 left;
        bytes32 right;

        for (uint32 i = 0; i < levels; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeros[i];
                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }

            currentLevelHash = hashLeftRight(left, right);
            currentIndex /= 2;
        }

        currentRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        roots[currentRootIndex] = currentLevelHash;
        return nextIndex - 1;
    }

    function isKnownRoot(bytes32 _root) public view returns (bool) {
        if (uint256(_root) == 0) {
            return false;
        }

        uint32 i = currentRootIndex;
        do {
            if (roots[i] == _root) {
                return true;
            }
            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }
            i--;
        } while (i != currentRootIndex);
        return false;
    }

    function getLastRoot() public view returns (bytes32) {
        return roots[currentRootIndex];
    }
}