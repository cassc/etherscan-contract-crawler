// SPDX-License-Identifier: MIT
// Indelible Labs LLC

pragma solidity 0.8.17;

interface IIndelibleProRenderer {
    function tokenURI(uint tokenId) external view returns (string memory);
}