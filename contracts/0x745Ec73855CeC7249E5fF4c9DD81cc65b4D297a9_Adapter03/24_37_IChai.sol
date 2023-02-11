// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IChai {
    function join(address dst, uint256 wad) external;

    function exit(address src, uint256 wad) external;
}