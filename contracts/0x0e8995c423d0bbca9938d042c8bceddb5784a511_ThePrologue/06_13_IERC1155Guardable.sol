// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC1155Guardable is IERC165 {
    // Interface ID 0x48615a68

    error TokenIsLocked();
    error CallerGuardianMismatch(address caller, address guardian);
    error InvalidGuardian();

    event GuardianAdded(
        address indexed addressGuarded, address indexed guardian
    );
    event GuardianRemoved(address indexed addressGuarded);

    function lockApprovals(address guardian) external;

    function unlockApprovals(address tokenOwner) external;

    function setApprovalForAll(address operator, bool approved) external;

    function guardianOf(address tokenOwner) external view returns (address);
}