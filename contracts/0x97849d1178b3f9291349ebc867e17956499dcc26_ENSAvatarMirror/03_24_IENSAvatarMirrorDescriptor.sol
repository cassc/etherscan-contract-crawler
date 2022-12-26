// SPDX-License-Identifier: CC0-1.0

/// @title IENSAvatarMirrorDescriptor

/**
 *        ><<    ><<<<< ><<    ><<      ><<
 *      > ><<          ><<      ><<      ><<
 *     >< ><<         ><<       ><<      ><<
 *   ><<  ><<        ><<        ><<      ><<
 *  ><<<< >< ><<     ><<        ><<      ><<
 *        ><<        ><<       ><<<<    ><<<<
 */

pragma solidity ^0.8.17;

interface IENSAvatarMirrorDescriptor {
    function tokenURI(string memory domain, bytes32 node) external view returns (string memory);
}