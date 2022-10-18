// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGenesis {
    function walletOfOwner(address owner) external view returns (uint256[] memory);
}