// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrongXNFT {
    function mint(address to, uint id, uint amount, bytes calldata data) external;
    function burn(address from, uint id, uint amount) external;
}