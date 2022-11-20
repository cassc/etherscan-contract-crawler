// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtMintAllocator {
    function init(address collection, uint8[3] memory mintAlloc) external;

    function update(
        address collection,
        uint256 membershipId,
        uint256 amount
    ) external;

    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        returns (uint256);

    function getAvailableMintsForMembership(
        address collection,
        uint256 membershipId
    ) external view returns (uint256);

    function getMembershipMints(address collection, uint256 membershipId)
        external
        view
        returns (uint256);
}