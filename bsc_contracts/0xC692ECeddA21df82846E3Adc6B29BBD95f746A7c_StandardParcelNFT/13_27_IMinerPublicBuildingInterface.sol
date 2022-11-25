// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import '../Municipality.sol';

interface IMinerPublicBuildingInterface {
    function mintParcelsBundle(address user, Municipality.Parcel [] memory) external returns (uint256[] memory);
    function mintMinersBundle(address user, uint256 minersAmount) external returns (uint256, uint256);
}