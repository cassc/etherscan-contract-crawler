// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUtherTrunks {
    function privateMint(address to, uint256 id, uint256 amount, bytes memory data) external;
    function publicMint(address to, uint256 id, uint256 amount, bytes memory data) external;
}