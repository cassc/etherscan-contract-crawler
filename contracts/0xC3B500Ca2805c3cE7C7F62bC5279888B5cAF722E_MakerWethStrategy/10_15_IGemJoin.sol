// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IGemJoin {
    function join(address, uint256) external payable;

    function exit(address, uint256) external;
}