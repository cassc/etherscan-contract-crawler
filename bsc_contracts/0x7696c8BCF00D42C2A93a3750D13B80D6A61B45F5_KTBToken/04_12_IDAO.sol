// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IDAO {
    function getRelations(address) external view returns (address[] memory);
}
