//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface INonFungiblePositionManager {
    function mint(address, uint256) external;

    function burn(uint256) external;

    function ownerOf(uint256) external view returns (address);
}