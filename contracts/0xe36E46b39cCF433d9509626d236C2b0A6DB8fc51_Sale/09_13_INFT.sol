//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;
interface INFT{
    function mint(address user, bytes calldata _URI, uint256 tokenId) external;
}