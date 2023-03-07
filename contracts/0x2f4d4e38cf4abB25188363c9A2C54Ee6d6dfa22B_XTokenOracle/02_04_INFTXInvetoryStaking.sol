//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTXInvetoryStaking {
    function xTokenShareValue(uint256 vaultId) external view returns (uint256);
}