// SPDX-License-Identifier: CC0-1.0

/// @title IENSAvatarMirrorNameLabeler

/**
 *        ><<    ><<<<< ><<    ><<      ><<
 *      > ><<          ><<      ><<      ><<
 *     >< ><<         ><<       ><<      ><<
 *   ><<  ><<        ><<        ><<      ><<
 *  ><<<< >< ><<     ><<        ><<      ><<
 *        ><<        ><<       ><<<<    ><<<<
 */

pragma solidity ^0.8.17;

interface IENSAvatarMirrorNameLabeler {
    function namehash(string memory domain) external pure returns (bytes32);
}