// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IERC173 {
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function owner() external view returns (address);

    function transferOwnership(address _to) external;
}