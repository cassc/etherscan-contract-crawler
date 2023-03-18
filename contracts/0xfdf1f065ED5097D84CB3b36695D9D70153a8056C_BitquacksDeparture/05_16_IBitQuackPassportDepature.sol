// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBitQuackPassportDepature {
    function transferOrdinal(uint256 id, string memory ordAddress) external returns (bool);
}