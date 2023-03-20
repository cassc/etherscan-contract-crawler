// contracts/Project.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ImToken {
    function shares(address nft, uint256 tokenId) external view returns(uint256);

    function totalShares() external view returns (uint256);
}