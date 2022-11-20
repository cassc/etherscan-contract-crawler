// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArtMinter {
    function mintOne(address collection, uint256 membershipId) external payable;

    function mint(address collection, uint256 amount) external payable;

    function getPrice(address collection) external view returns (uint256);

    function addPricing(address collection, address artist) external;

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