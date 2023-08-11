// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IV1Memberships {
    function ownerOf(
        uint256 tokenId
    ) external view returns (address);

    function getMembershipLevelById(
        uint256 tokenId
    ) external view returns (uint256);

    function burnMembership(uint256 tokenId) external;

    function setMembershipContractV2(
        address _membershipContractV2
    ) external;
}