// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4 < 0.9.0;

import "./IERC721A.sol";

interface IDDW is IERC721A {

    function isTokenPrivileged(uint256 tokenId) external view returns(bool isPrivileged);

    function burn(uint256 tokenId) external;
}