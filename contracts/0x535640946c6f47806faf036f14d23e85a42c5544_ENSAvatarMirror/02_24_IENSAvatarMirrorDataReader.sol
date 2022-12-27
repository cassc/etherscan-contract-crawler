// SPDX-License-Identifier: CC0-1.0

/// @title IENSAvatarMirrorDataReader

/**
 *        ><<    ><<<<< ><<    ><<      ><<
 *      > ><<          ><<      ><<      ><<
 *     >< ><<         ><<       ><<      ><<
 *   ><<  ><<        ><<        ><<      ><<
 *  ><<<< >< ><<     ><<        ><<      ><<
 *        ><<        ><<       ><<<<    ><<<<
 */

pragma solidity ^0.8.17;

interface IENSAvatarMirrorDataReader {
    function substring(string memory str, uint256 startIndex, uint256 endIndex) external pure returns (string memory);
    function parseAddrString(string memory addr) external pure returns (address);
    function parseIntString(string memory intStr) external pure returns (uint256);
    function uriScheme(string memory uri) external pure returns (bytes32 scheme, uint256 len, bytes32 root);
}