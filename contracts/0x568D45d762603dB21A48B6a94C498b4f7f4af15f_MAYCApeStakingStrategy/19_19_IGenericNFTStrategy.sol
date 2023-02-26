// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IGenericNFTStrategy {
    enum Kind {
        STANDARD,
        FLASH
    }

    function kind() external view returns (Kind);
    function depositAddress(address _account) external view returns (address);
}