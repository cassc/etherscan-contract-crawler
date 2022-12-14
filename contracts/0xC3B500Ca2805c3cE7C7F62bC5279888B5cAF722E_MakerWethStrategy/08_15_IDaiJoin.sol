// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IDaiJoin {
    function exit(address usr, uint256 wad) external;

    function join(address, uint256) external payable;
}