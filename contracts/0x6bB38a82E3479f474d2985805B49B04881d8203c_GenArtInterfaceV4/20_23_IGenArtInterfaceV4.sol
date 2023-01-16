// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtInterfaceV4 {
    function isGoldToken(uint256 _membershipId) external view returns (bool);

    function getMembershipsOf(address account)
        external
        view
        returns (uint256[] memory);

    function ownerOfMembership(uint256 _membershipId)
        external
        view
        returns (address, bool);

    function isVaulted(uint256 _membershipId) external view returns (bool);
}