/*
 * Copyright (C) 2022  Christian Felde
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma solidity ^0.8.0;

abstract contract NuPoW {
    bytes32 public constant CFELDE = 0xffff000cfe1de000cfe1de000cfe1de000cfe1de000cfe1de000cfe1de000000;

    uint public immutable CHAIN_LENGTH_TARGET;
    uint public immutable MAX_MINT;
    uint public immutable STALLED_DURATION;

    uint public nextMint;
    uint public chainLength;
    uint public stalledTimestamp;
    uint public lastBlockNumber;
    bytes32 public lastHash;
    address public lastChallenger;

    event ChainProgress(address indexed challenger, uint chainLength, bytes32 oldHash, bytes32 newHash, uint nextMint, string tag);

    constructor(
        uint _CHAIN_LENGTH_TARGET,
        uint8 _MAX_MINT_OFFSET,
        uint _STALLED_DURATION
    ) {
        CHAIN_LENGTH_TARGET = _CHAIN_LENGTH_TARGET;
        MAX_MINT = 1 << _MAX_MINT_OFFSET;
        STALLED_DURATION = _STALLED_DURATION;
        nextMint = MAX_MINT;
    }

    // Manage stalled and nextMint
    function _manage(
        bytes32 stalledDifficulty
    ) internal {
        unchecked {
            if (block.timestamp > stalledTimestamp) {
                if (chainLength < CHAIN_LENGTH_TARGET) {
                    nextMint = nextMint << 1;
                    if (nextMint == 0) nextMint = 1;
                    else if (nextMint > MAX_MINT) nextMint = MAX_MINT;
                } else if (chainLength > CHAIN_LENGTH_TARGET) {
                    nextMint = nextMint >> 1;
                }

                chainLength = 0;
                lastHash = stalledDifficulty;
                stalledTimestamp = block.timestamp + STALLED_DURATION;
            }
        }
    }

    // Manage hash and progress
    function _challenge(
        uint seed,
        string memory tag
    ) internal returns (uint, bool) {
        unchecked {
            bytes32 hash = keccak256(abi.encode(seed, msg.sender, lastHash));

            if (hash < lastHash && block.number > lastBlockNumber) {
                chainLength++;

                emit ChainProgress(msg.sender, chainLength, lastHash, hash, nextMint, tag);

                lastHash = hash;
                lastChallenger = msg.sender;
                lastBlockNumber = block.number;
                stalledTimestamp = block.timestamp + STALLED_DURATION;

                return (nextMint, true);
            } else {
                return (0, false);
            }
        }
    }

    // Base implementation of mint (actual minting left to inheriting contract)
    function mint(
        uint seed,
        string memory tag
    ) public virtual returns (
        uint mintValue,
        bool progress
    ) {
        _manage(blockhash(block.number - 1) | CFELDE);
        (mintValue, progress) = _challenge(seed, tag);
    }
}