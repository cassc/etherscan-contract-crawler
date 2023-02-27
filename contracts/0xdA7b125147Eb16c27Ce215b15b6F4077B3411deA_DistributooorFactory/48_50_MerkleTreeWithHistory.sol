// https://tornado.cash
/*
 * d888888P                                           dP              a88888b.                   dP
 *    88                                              88             d8'   `88                   88
 *    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
 *    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
 *    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
 *    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
 * ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
 */

/// @notice This is a modified version of MerkleTreeWithHistory from tornado:
///     * Not limited by a finite field size
///     * Uses keccak256 instead of MiMC
///     * Proxy friendly

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MerkleTreeWithHistory is Initializable {
    uint256 public constant ZERO_VALUE =
        uint256(keccak256(abi.encodePacked(address(0))));

    uint32 public levels;
    bytes32[] public _zeros;

    // the following variables are made public for easier testing and debugging and
    // are not supposed to be accessed in regular code

    // filledSubtrees and roots could be bytes32[size], but using mappings makes it cheaper because
    // it removes index range check on every interaction
    mapping(uint256 => bytes32) public filledSubtrees;
    mapping(uint256 => bytes32) public roots;
    uint32 public constant ROOT_HISTORY_SIZE = 30;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;

    function __MerkleTreeWithHistory_init(
        uint32 _levels
    ) internal onlyInitializing {
        require(_levels > 0, "_levels should be greater than zero");
        require(_levels < 32, "_levels should be less than 32");
        levels = _levels;

        // Build zero values
        _zeros.push(bytes32(ZERO_VALUE));
        for (uint256 i = 1; i <= _levels; ++i) {
            _zeros.push(hashLeftRight(_zeros[i - 1], _zeros[i - 1]));
        }

        for (uint32 i = 0; i < _levels; ++i) {
            filledSubtrees[i] = zeros(i);
        }

        roots[0] = zeros(_levels - 1);
    }

    /// @dev Hash 2 tree leaves, returns MiMC(_left, _right)
    function hashLeftRight(
        bytes32 _left,
        bytes32 _right
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_left, _right));
    }

    function _insert(bytes32 _leaf) internal returns (uint32 index) {
        uint32 _nextIndex = nextIndex;
        require(
            _nextIndex != uint32(2) ** levels,
            "Merkle tree is full. No more leaves can be added"
        );
        uint32 currentIndex = _nextIndex;
        bytes32 currentLevelHash = _leaf;
        bytes32 left;
        bytes32 right;

        for (uint32 i = 0; i < levels; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeros(i);
                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }
            currentLevelHash = hashLeftRight(left, right);
            currentIndex /= 2;
        }

        uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        currentRootIndex = newRootIndex;
        roots[newRootIndex] = currentLevelHash;
        nextIndex = _nextIndex + 1;
        return _nextIndex;
    }

    /// @dev Whether the root is present in the root history
    function isKnownRoot(bytes32 _root) public view returns (bool) {
        if (_root == 0) {
            return false;
        }
        uint32 _currentRootIndex = currentRootIndex;
        uint32 i = _currentRootIndex;
        do {
            if (_root == roots[i]) {
                return true;
            }
            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }
            i--;
        } while (i != _currentRootIndex);
        return false;
    }

    /// @dev Returns the last root
    function getLastRoot() public view returns (bytes32) {
        return roots[currentRootIndex];
    }

    function zeros(uint256 i) public view returns (bytes32) {
        require(i < levels, "Out of bounds");
        return _zeros[i];
    }
}