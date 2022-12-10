// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPandaFarms {
    function burn(address owner, uint256 id, uint256 value) external;
    function burnBatch(address owner, uint256[] memory ids, uint256[] memory values) external;
}