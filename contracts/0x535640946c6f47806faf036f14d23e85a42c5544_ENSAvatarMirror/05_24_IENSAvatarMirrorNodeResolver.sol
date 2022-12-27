// SPDX-License-Identifier: CC0-1.0

/// @title IENSAvatarMirrorNodeResolver

/**
 *        ><<    ><<<<< ><<    ><<      ><<
 *      > ><<          ><<      ><<      ><<
 *     >< ><<         ><<       ><<      ><<
 *   ><<  ><<        ><<        ><<      ><<
 *  ><<<< >< ><<     ><<        ><<      ><<
 *        ><<        ><<       ><<<<    ><<<<
 */

pragma solidity ^0.8.17;

interface IENSAvatarMirrorNodeResolver {
    function getNodeOwner(bytes32 node) external view returns (address);
    function resolveText(bytes32 node, string memory key) external view returns (string memory);
    function reverseNode(address addr) external view returns (bytes32);
    function reverseDomain(address addr) external view returns (string memory);
}