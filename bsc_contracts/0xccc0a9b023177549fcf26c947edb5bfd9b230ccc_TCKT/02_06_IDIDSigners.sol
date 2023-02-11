// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

uint256 constant END_TS_OFFSET = 112;

uint256 constant END_TS_MASK = uint256(type(uint64).max) << 112;

uint256 constant WITHDRAW_OFFSET = 176;

uint256 constant WITHDRAW_MASK = uint256(type(uint48).max) << 176;

interface IDIDSigners {
    /**
     * Maps a signer node address to a bit packed struct.
     *
     *`signerInfo` layout:
     * |-- color --|-- withdraw --|--  endTs --|-- deposit --|-- startTs --|
     * |--   32  --|--    48    --|--   64   --|--   48    --|--   64    --|
     */
    function signerInfo(address signer) external view returns (uint256);
}