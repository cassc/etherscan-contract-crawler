// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
* @title interface represents hook contract that can be called every time when role created/granted/revoked
*/
interface ICommunityHook  is IERC165 {
    function roleGranted(bytes32 role, uint8 roleIndex, address account) external;
    function roleRevoked(bytes32 role, uint8 roleIndex, address account) external;
    function roleCreated(bytes32 role, uint8 roleIndex) external;

}