// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtInterfaceV3 {
    function isGoldToken(uint256 _membershipId) external view returns (bool);

    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        returns (uint256);

    function getMembershipsOf(address account)
        external
        view
        returns (uint256[] memory);

    function ownerOfMembership(uint256 _membershipId) external view returns (address);
}