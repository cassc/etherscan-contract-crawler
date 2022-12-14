// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IAdventureApproval {
    function setAdventuresApprovedForAll(address operator, bool approved) external;
    function areAdventuresApprovedForAll(address owner, address operator) external view returns (bool);
    function isAdventureWhitelisted(address account) external view returns (bool);
}