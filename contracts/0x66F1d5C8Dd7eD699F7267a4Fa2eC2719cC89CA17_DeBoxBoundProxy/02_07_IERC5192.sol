// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

interface IERC5192 {
    function verifyToken(uint256 id, string memory meta, uint256 mtype) external view returns (bool);
    function safeMint(string memory meta, uint256 period, uint256 mtype) external returns (uint256);
}