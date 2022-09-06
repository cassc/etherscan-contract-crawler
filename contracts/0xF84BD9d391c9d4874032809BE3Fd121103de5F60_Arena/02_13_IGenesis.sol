// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGenesis {

    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}