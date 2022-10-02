// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IGYMNETWORK {
    function getGYMNETPrice() external view returns (uint256);

    function getBNBPrice() external view returns (uint256);
}