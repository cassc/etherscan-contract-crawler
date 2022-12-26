// SPDX-License-Identifier: CC0-1.0

/// @title IENSAvatarMirrorDescriptorDefault

/**
 *        ><<    ><<<<< ><<    ><<      ><<
 *      > ><<          ><<      ><<      ><<
 *     >< ><<         ><<       ><<      ><<
 *   ><<  ><<        ><<        ><<      ><<
 *  ><<<< >< ><<     ><<        ><<      ><<
 *        ><<        ><<       ><<<<    ><<<<
 */

pragma solidity ^0.8.17;

interface IENSAvatarMirrorDescriptorDefault {
    /* solhint-disable func-name-mixedcase */
    function IMAGE_UNINITIALIZED() external pure returns (string memory);
    function IMAGE_ERROR() external pure returns (string memory);
    function buildTokenURI(string memory domain, string memory image) external pure returns (string memory);
}