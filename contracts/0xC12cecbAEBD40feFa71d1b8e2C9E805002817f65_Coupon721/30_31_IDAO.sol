// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDAO {
    function getPrice() external view returns (uint256);

    function epoch() external view returns (uint256);
}